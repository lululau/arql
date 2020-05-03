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
        db_config
      end
    end

    def config
      @config ||= YAML.load(IO.read(@options.config_file)).with_indifferent_access
    end

    def db_config
      config[:db][@options.env]
    end

    def run!
      show_sql if should_show_sql?
      write_sql if should_write_sql?
      append_sql if should_append_sql?
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

    def should_show_sql?
      @options.show_sql || db_config[:show_sql]
    end

    def should_write_sql?
      @options.write_sql || db_config[:write_sql]
    end

    def should_append_sql?
      @options.append_sql || db_config[:append_sql]
    end

    def show_sql
      @log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(@log_io)
      @log_io << STDOUT
    end

    def write_sql
      write_sql_file = @options.write_sql || db_config[:write_sql]
      @log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(@log_io)
      @log_io << File.new(write_sql_file, 'w')
    end

    def append_sql
      write_sql_file = @options.append_sql || db_config[:append_sql]
      @log_io ||= MultiIO.new
      ActiveRecord::Base.logger = Logger.new(@log_io)
      @log_io << File.new(write_sql_file, 'a')
    end
  end
end
