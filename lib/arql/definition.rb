require 'arql/concerns'
require 'arql/vd'

module Arql

  class BaseModel < ::ActiveRecord::Base
    self.abstract_class = true

    define_singleton_method(:indexes) do
      connection.indexes(table_name).map do |idx|
        {
          Table: idx.table,
          Name: idx.name,
          Columns: idx.columns.join(', '),
          Unique: idx.unique,
          Comment: idx.comment
        }
      end.t
    end

    define_singleton_method(:like) do |**args|
      send(:ransack, "#{args.keys.first}_cont" => args.values.first).result
    end

    def self.method_missing(method_name, *args, &block)
      if method_name.to_s =~ /^(.+)_like$/
        attr_name = $1.to_sym
        return super unless has_attribute?(attr_name)
        send(:like, $1 => args.first)
      else
        super
      end
    end
  end

  class Definition
    attr :connection, :ssh_proxy, :options, :models, :namespace_module, :namespace

    def redefine
      @models.each do |model|
        @namespace_module.send :remove_const, model[:model].class_name.to_sym if model[:model]
        @namespace_module.send :remove_const, model[:abbr].sub(/^#{@namespace}::/, '').to_sym if model[:abbr]
      end
      @models = []
      @connection.tables.each do |table_name|
        model = define_model_from_table(table_name, @primary_keys[table_name])
        next unless model

        model[:comment] = @comments[table_name]
        @models << model
      end
      App.instance&.load_initializer!
    end

    def initialize(options)
      @models = []
      @options = options
      @classify_method = @options[:singularized_table_names] ? :camelize : :classify
      @ssh_proxy = start_ssh_proxy if options[:ssh].present?
      create_connection

      tables = @connection.tables
      if @connection.adapter_name == 'Mysql2'
        require 'arql/ext/active_record/connection_adapters/abstract_mysql_adapter'
        @comments = @connection.table_comment_of_tables(tables)
        @primary_keys = @connection.primary_keys_of_tables(tables)
      else
        @comments = tables.map { |t| [t, @connection.table_comment(t)] }.to_h
        @primary_keys = tables.map { |t| [t, @connection.primary_keys(t)] }.to_h
      end

      tables.each do |table_name|
        model = define_model_from_table(table_name, @primary_keys[table_name])
        next unless model

        model[:comment] = @comments[table_name]
        @models << model
      end

      order_column = @options[:order_column]
      if order_column
        Thread.new do
          @models.each do |model|
            model_class = model[:model]
            model_class.implicit_order_column = order_column if model_class.column_names.include?(order_column)
          end
        end
      end
    end

    def model_names_mapping
      @model_names_mapping ||= @options[:model_names] || {}
    end

    def define_model_from_table(table_name, primary_keys)
      model_name = make_model_name(table_name)
      return unless model_name

      model_class = make_model_class(table_name, primary_keys)
      @namespace_module.const_set(model_name, model_class)
      abbr_name = make_model_abbr_name(model_name, table_name)
      @namespace_module.const_set(abbr_name, model_class)

      # if Arql::App.instance.environments&.size == 1
      #   Object.const_set(model_name, model_class)
      #   Object.const_set(abbr_name, model_class)
      # end

      { model: model_class, abbr: "#@namespace::#{abbr_name}", table: table_name }
    end

    def make_model_abbr_name(model_name, table_name)
      mapping = model_names_mapping[table_name]
      return mapping[1] if mapping.present? && mapping.is_a?(Array) && mapping.size > 1

      bare_abbr = model_name.gsub(/[a-z]*/, '')
      model_abbr_name = bare_abbr
      1000.times do |idx|
        abbr = idx.zero? ? bare_abbr : "#{bare_abbr}#{idx + 1}"
        unless @namespace_module.const_defined?(abbr)
          model_abbr_name = abbr
          break
        end
      end
      model_abbr_name
    end

    def make_model_name(table_name)
      mapping = model_names_mapping[table_name]
      if mapping.present?
        return mapping if mapping.is_a?(String)
        return mapping.first if mapping.is_a?(Array) && mapping.size >= 1
      end
      table_name_prefixes = @options[:table_name_prefixes] || []
      model_name = table_name_prefixes.each_with_object(table_name.dup) do |prefix, name|
        name.sub!(/^#{prefix}/, '')
      end.send(@classify_method)
      model_name.gsub!(/^Module|Class|BaseModel$/, '$&0')
      if model_name !~ /^[A-Z][A-Za-z0-9_]*$/
        warn "Could not make model name from table name: #{table_name}"
        return
      end
      model_name
    end

    def make_model_class(table_name, primary_keys)
      options = @options
      Class.new(@base_model) do
        include Arql::Extension
        if primary_keys.is_a?(Array) && primary_keys.size > 1
          self.primary_keys = primary_keys
        else
          self.primary_key = primary_keys&.first
        end
        self.table_name = table_name
        self.inheritance_column = nil
        ActiveRecord.default_timezone = :local
        if options[:created_at].present?
          define_singleton_method :timestamp_attributes_for_create do
            options[:created_at]
          end
        end

        if options[:updated_at].present?
          define_singleton_method :timestamp_attributes_for_update do
            options[:updated_at]
          end
        end
      end
    end

    def start_ssh_proxy
      ssh_config = @options[:ssh]
      Arql::SSHProxy.new(
        ssh_config.slice(:host, :user, :port, :password)
          .merge(forward_host: @options[:host],
            forward_port: @options[:port],
            local_port: ssh_config[:local_port]))
    end

    def get_connection_options
      connect_conf = @options.slice(:adapter, :host, :username, :password,
                                :database, :encoding, :pool, :port, :socket)
      connect_conf.merge!(@ssh_proxy.database_host_port) if @ssh_proxy
      connect_conf
    end

    def create_connection
      @namespace = @options[:namespace]
      connection_opts = get_connection_options
      print "Establishing DB connection to #{connection_opts[:host]}:#{connection_opts[:port]}"
      @namespace_module = create_namespace_module(@namespace)
      @base_model = @namespace_module.const_set('BaseModel', Class.new(BaseModel))
      @base_model.class_eval do
        include ::Arql::Concerns::TableDataDefinition
        self.abstract_class = true
        establish_connection(connection_opts)
        class << self
          attr_accessor :definition
        end
      end
      print "\u001b[2K"
      puts "\rDB connection to #{connection_opts[:host]}:#{connection_opts[:port]} established\n"
      @connection = @base_model.connection
      @base_model.define_singleton_method(:dump) do |filename, no_create_db = false|
        Arql::Mysqldump.new(options).dump_database(filename, no_create_db)
      end
      @base_model.definition = self
    end

    def create_namespace_module(namespace)
      definition = self

      Object.const_set(namespace, Module.new {

        define_singleton_method(:config) do
          definition.options
        end

        define_singleton_method(:models) do
          definition.models.map { |m| m[:model] }
        end

        define_singleton_method(:tables) do
          definition.models.map { |m| m[:table] }
        end

        define_singleton_method(:model_names) do
          models.map(&:name)
        end

        define_singleton_method(:q) do |sql|
          definition.connection.exec_query(sql)
        end

        define_singleton_method(:create_table) do |table_name, **options, &blk|
          definition.connection.create_table(table_name, **options, &blk)
        end

        define_singleton_method(:dump) do |filename, no_create_db = false|
          Arql::Mysqldump.new(definition.options).dump_database(filename, no_create_db)
        end
      })
    end
  end
end
