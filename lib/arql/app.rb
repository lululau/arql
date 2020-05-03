require 'active_support/core_ext/hash'

module Arql
  class App
    def initialize(options)
      @options = options
      Connection.open(connect_options)
      @definition = Definition.new
    end

    def connect_options
      if use_db_cmd_options?
        {
          adapter: @options.db_adapter,
          host: @options.db_host,
          username: @options.db_user,
          password: @options.db_password || '',
          database: @options.db_name,
          encoding: @options.db_encoding,
          pool: @options.db_pool,
          port: @options.db_port
        }
      else
        config[:db][@options.env]
      end
    end

    def config
      @config ||= YAML.load(IO.read(@options.config_file)).with_indifferent_access
    end

    def run!
      if @options.code.present?
        eval(@options.code)
      elsif @options.args.present?
        @options.args.each { |rb| load(rb) }
      else
        run_repl!
      end
    end

    def run_repl!
      Repl.new
    end

    def use_db_cmd_options?
      @options.db_host.present?
    end
  end
end
