module Arql
  class App

    class << self
      attr_accessor :log_io, :env, :prompt, :instance, :connect_options

      def config
        @@effective_config
      end

      def prompt
        if env
          env
        else
          File.basename(@@effective_config[:database])
        end
      end
    end

    def initialize(options)
      require "arql/connection"
      require "arql/definition"
      @options = options
      App.env = @options.env
      App.connect_options = connect_options
      Connection.open(App.connect_options)
      print "Defining models..."
      @definition = Definition.new(effective_config)
      print "\u001b[2K"
      puts "\rModels defined"
      print "Running initializers..."
      load_initializer!
      print "\u001b[2K"
      puts "\rInitializers loaded"
      App.instance = self
    end

    def connect_options
      connect_conf = effective_config.slice(:adapter, :host, :username,
                             :password, :database, :encoding,
                             :pool, :port, :socket)
      if effective_config[:ssh].present?
        connect_conf.merge!(start_ssh_proxy!)
      end

      connect_conf
    end

    def load_initializer!
      return unless effective_config[:initializer]
      initializer_file = File.expand_path(effective_config[:initializer])
      unless File.exist?(initializer_file)
        STDERR.puts "Specified initializer file not found, #{effective_config[:initializer]}"
        exit(1)
      end
      load(initializer_file)
    end

    def start_ssh_proxy!
      ssh_config = effective_config[:ssh]
      local_ssh_proxy_port = Arql::SSHProxy.connect(ssh_config.slice(:host, :user, :port, :password).merge(
                                                                                                           forward_host: effective_config[:host],
                                                                                                           forward_port: effective_config[:port],
                                                                                                           local_port: ssh_config[:local_port]))
      {
        host: '127.0.0.1',
        port: local_ssh_proxy_port
      }
    end

    def config
      @config ||= YAML.load(IO.read(File.expand_path(@options.config_file)), aliases: true).with_indifferent_access
    rescue ArgumentError
      @config ||= YAML.load(IO.read(File.expand_path(@options.config_file))).with_indifferent_access
    end

    def selected_config
      if @options.env.present? && !config[@options.env].present?
        STDERR.puts "Specified ENV `#{@options.env}' not exists"
      end
      if env = @options.env
        config[env]
      else
        {}
      end
    end

    def effective_config
      @@effective_config ||= nil
      unless @@effective_config
        @@effective_config = selected_config.deep_merge(@options.to_h)
        if @@effective_config[:adapter].blank?
          @@effective_config[:adapter] = 'sqlite3'
        end
        @@effective_config[:database] = File.expand_path(@@effective_config[:database]) if @@effective_config[:adapter] == 'sqlite3'
      end
      @@effective_config
    end

    def run!
      show_sql if should_show_sql?
      write_sql if should_write_sql?
      append_sql if should_append_sql?
      if effective_config[:code].present?
        eval(effective_config[:code])
      elsif effective_config[:args].present?
        effective_config[:args].first.tap { |file| load(file) }
      elsif STDIN.isatty
        run_repl!
      else
        eval(STDIN.read)
      end
    end

    def run_repl!
      Repl.new
    end

    def should_show_sql?
      effective_config[:show_sql]
    end

    def should_write_sql?
      effective_config[:write_sql]
    end

    def should_append_sql?
      effective_config[:append_sql]
    end

    def show_sql
      App.log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(App.log_io)
      App.log_io << STDOUT
    end

    def write_sql
      write_sql_file = effective_config[:write_sql]
      App.log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(App.log_io)
      App.log_io << File.new(write_sql_file, 'w')
    end

    def append_sql
      write_sql_file = effective_config[:append_sql]
      App.log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(App.log_io)
      App.log_io << File.new(write_sql_file, 'a')
    end
  end
end
