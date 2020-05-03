require 'optparse'
require 'ostruct'

module Arql
  class Cli
    class << self
      def start
        parse_options!
        App.new(@options).run!
      end

      def parse_options!
        @options = OpenStruct.new(db_adapter: 'mysql2',
                                  db_encoding: 'UFF-8',
                                  db_pool: 5,
                                  config_file: default_config_file,
                                  initializer: default_initializer)


        OptionParser.new do |opts|
          opts.banner = <<~EOF
          Usage: arql [options] [ruby file]

            If neither [ruby file] nor -e option specified, a Pry REPL will be launched,
            otherwise the specified ruby file or -e option value will be run, and no REPL launched

          EOF

          opts.on('-cCONFIG_FILE', '--conf=CONFIG_FILE', 'Specify config file, default is $HOME/.arql.yml, or $HOME/.arql.d/init.yml.') do |config_file|
            @options.config_file = config_file
          end

          opts.on('-iINITIALIZER', '--initializer=INITIALIZER', 'Specify initializer ruby file, default is $HOME/.arql.rb, or $HOME/.arql.d/init.rb.') do |initializer|
            @options.initializer = initializer
          end

          opts.on('-EENVIRON', '--env=ENVIRON', 'Specify config environment.') do |env|
            @options.env = env
          end

          opts.on('-jJAVA_CONFIG', '--java-conf=JAVA_CONFIG', 'Use JDBC config in JAVA_CONFIG file, if directory sepcified, first *.properties/*.yml file found in the directory will be used') do |config_file|
            @options.config_file = config_file
          end

          opts.on('-ADB_ADAPTER', '--db-adapter=DB_ADAPTER', 'Specify DB Adapter, default is mysql2') do |db_adapter|
            @options.db_adapter = db_adapter
          end

          opts.on('-HDB_HOST', '--db-host=DB_HOST', 'Specify DB host, if specified -E option will be ignored') do |db_host|
            @options.db_host = db_host
          end

          opts.on('-PDB_PORT', '--db-port=DB_PORT', 'Specify DB port, if specified -E option will be ignored') do |db_port|
            @options.db_port = db_port.to_i
          end

          opts.on('-DDB_NAME', '--db-name=DB_NAME', 'Specify database name, if specified -E option will be ignored') do |db_name|
            @options.db_name = db_name
          end

          opts.on('-UDB_USER', '--db-user=DB_USER', 'Specify database user, if specified -E option will be ignored') do |db_user|
            @options.db_user = db_user
          end

          opts.on('-pDB_PASSWORD', '--db-password=DB_PASSWORD', 'Specify database password, if specified -E option will be ignored') do |db_password|
            @options.db_password = db_password
          end

          opts.on('-n', '--db-encoding=DB_ENCODING', 'Specify database encoding, default is UTF-8') do |db_encoding|
            @options.db_encoding = db_encoding
          end

          opts.on('-o', '--db-pool=DB_POOL', 'Specify database pool size, default is 5') do |db_pool|
            @options.db_pool = db_pool
          end

          opts.on('-eCODE', '--eval=CODE', 'evaluate CODE') do |code|
            @options.code = code
          end

          opts.on('-s', '--show-sql', 'Show SQL on STDOUT') do
            @options.show_sql = true
          end

          opts.on('-wOUTOUT', '--write-sql=OUTPUT', 'Write SQL to OUTPUT file') do |file|
            @options.write_sql = file
          end

          opts.on('-aOUTPUT', '--append-sql=OUTPUT', 'Append SQL to OUTPUT file') do |file|
            @options.append_sql = file
          end

          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            exit
          end

        end.parse!

        @options.args = ARGV
      end

      def default_config_file
        conf = File.expand_path('~/.arql.yml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql.yaml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql/init.yml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql/init.yaml')
        return conf if File.file?(conf)
      end

      def default_initializer
        conf = File.expand_path('~/.arql.yml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql.yaml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql/init.yml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql/init.yaml')
        return conf if File.file?(conf)
      end
    end
  end
end
