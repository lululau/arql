require 'net/ssh/gateway'

module Arql
  class App

    class << self
      def config
        @@effective_config
      end

      def local_ssh_proxy_port
        @@local_ssh_proxy_port
      end
    end

    def initialize(options)
      @options = options
      Connection.open(connect_options)
      @definition = Definition.new
    end

    def connect_options
      connect_conf = effective_config.slice(:adapter, :host, :username,
                             :password, :database, :encoding,
                             :pool, :port)
      if effective_config[:ssh].present?
        connect_conf.merge!(start_ssh_proxy!)
      end

      connect_conf
    end

    def start_ssh_proxy!
      ssh_config = effective_config[:ssh]
      @ssh_gateway = Net::SSH::Gateway.new(ssh_config[:host], ssh_config[:user], ssh_config.slice(:port, :password).symbolize_keys)
      @@local_ssh_proxy_port = @ssh_gateway.open(effective_config[:host], effective_config[:port], ssh_config[:local_port])
      {
        host: '127.0.0.1',
        port: @@local_ssh_proxy_port
      }
    end

    def config
      @config ||= YAML.load(IO.read(@options.config_file)).with_indifferent_access
    end

    def selected_config
      config[@options.env]
    end

    def effective_config
      @@effective_config ||= selected_config.deep_merge(@options.to_h)
    end

    def run!
      show_sql if should_show_sql?
      write_sql if should_write_sql?
      append_sql if should_append_sql?
      if effective_config[:code].present?
        eval(effective_config[:code])
      elsif effective_config[:args].present?
        effective_config[:args].each { |rb| load(rb) }
      else
        run_repl!
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
      @log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(@log_io)
      @log_io << STDOUT
    end

    def write_sql
      write_sql_file = effective_config[:write_sql]
      @log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(@log_io)
      @log_io << File.new(write_sql_file, 'w')
    end

    def append_sql
      write_sql_file = effective_config[:append_sql]
      @log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(@log_io)
      @log_io << File.new(write_sql_file, 'a')
    end
  end
end
