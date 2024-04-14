module Arql
  class App
    attr_accessor :log_io, :environments, :definitions, :options, :config

    class << self
      attr_accessor :instance

      def log_io
        instance.log_io
      end

      def log_io=(io)
        instance.log_io = io
      end

      # environment names
      def environments
        instance.environments
      end

      def prompt
        instance.prompt
      end

      def config
        instance.config
      end
    end

    def prompt
      if environments.present?
        environments.join('+')
      else
        File.basename(@options.database)
      end
    end

    def initialize(options)
      require "arql/definition"

      App.instance = self

      # command line options
      @options = options

      # env names
      @environments = @options.environments

      print "Defining models..."
      @definitions = config[:environments].each_with_object({}) do |(env_name, env_conf), h|
        h[env_name] = Definition.new(env_conf)
      end.with_indifferent_access

      print "\u001b[2K"
      puts "\rModels defined"
      print "Running initializers..."
      load_initializer!
      print "\u001b[2K"
      puts "\rInitializers loaded"
    end

    def load_initializer!
      return unless config[:options][:initializer]

      initializer_file = File.expand_path(config[:options][:initializer])
      unless File.exist?(initializer_file)
        $stderr.warn "Specified initializer file not found, #{config[:options][:initializer]}"
        exit(1)
      end
      load(initializer_file)
    end

    def config_from_file
      @config_from_file ||= YAML.safe_load(IO.read(File.expand_path(@options.config_file)), aliases: true).with_indifferent_access
    rescue ArgumentError
      @config_from_file ||= YAML.safe_load(IO.read(File.expand_path(@options.config_file))).with_indifferent_access
    end

    # Returns the configuration for config file.
    #  or default configuration (built from CLI options) if no environment specified
    def environ_config_from_file
      unless @options.environments&.all? { |env_names| config_from_file.key?(env_names) }
        $stderr.warn "Specified ENV `#{@options.env}' not exists in config file"
        exit(1)
      end
      conf = if @options.environments.present?
        @config_from_file.slice(*@options.environments)
      else
        { default: @options.to_h }.with_indifferent_access
      end
      conf.each do |env_name, env_conf|
        unless env_conf.key?(:namespace)
          env_conf[:namespace] = env_name.to_s.gsub(/[^a-zA-Z0-9]/, '_').camelize
        end
      end
    end

    # Returns the effective configuration for the application.
    # structure like:
    # {
    #   options: {show_sql: true,
    #             write_sql: 'output.sql',
    #             },
    #   environments: {
    #     development: {adapter: 'mysql2',
    #                   host: 'localhost',
    #                   port: 3306},
    #     test: {adapter: 'mysql2',
    #            host: 'localhost',
    #            port: 3306},
    #    }
    # }
    def config
      @config ||= {
        options: @options,
        environments: environ_config_from_file.each_with_object({}) { |(env_name, env_conf), h|
          conf = env_conf.deep_merge(@options.to_h)
          conf[:adapter] = 'sqlite3' if conf[:adapter].blank?
          conf[:database] = File.expand_path(conf[:database]) if conf[:adapter] == 'sqlite3'
          h[env_name] = conf
          h
        }.with_indifferent_access
      }
    end

    def run!
      show_sql if should_show_sql?
      write_sql if should_write_sql?
      append_sql if should_append_sql?
      if @options.code&.present?
        eval(@options.code)
      elsif @options.args.present?
        @options.args.first.tap { |file| load(file) }
      elsif $stdin.isatty
        run_repl!
      else
        eval($stdin.read)
      end
    end

    def run_repl!
      Repl.new
    end

    def should_show_sql?
      @options.show_sql
    end

    def should_write_sql?
      @options.write_sql
    end

    def should_append_sql?
      @options.append_sql
    end

    def show_sql
      App.log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(App.log_io)
      App.log_io << $stdout
    end

    def write_sql
      write_sql_file = @options.write_sql
      App.log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(App.log_io)
      App.log_io << File.new(write_sql_file, 'w')
    end

    def append_sql
      write_sql_file = @options.append_sql
      App.log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(App.log_io)
      App.log_io << File.new(write_sql_file, 'a')
    end
  end
end
