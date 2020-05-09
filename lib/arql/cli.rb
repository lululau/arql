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
        @options = OpenStruct.new(adapter: 'mysql2',
                                  encoding: 'utf8',
                                  pool: 5,
                                  config_file: default_config_file,
                                  initializer: default_initializer,
                                  ssh: {})


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

          opts.on('-eENVIRON', '--env=ENVIRON', 'Specify config environment.') do |env|
            @options.env = env
          end

          opts.on('-aDB_ADAPTER', '--db-adapter=DB_ADAPTER', 'Specify database Adapter, default is mysql2') do |db_adapter|
            @options.dapter = db_adapter
          end

          opts.on('-hDB_HOST', '--db-host=DB_HOST', 'Specify database host') do |db_host|
            @options.host = db_host
          end

          opts.on('-pDB_PORT', '--db-port=DB_PORT', 'Specify database port') do |db_port|
            @options.port = db_port.to_i
          end

          opts.on('-dDB_NAME', '--db-name=DB_NAME', 'Specify database name') do |db_name|
            @options.database = db_name
          end

          opts.on('-uDB_USER', '--db-user=DB_USER', 'Specify database user') do |db_user|
            @options.username = db_user
          end

          opts.on('-PDB_PASSWORD', '--db-password=DB_PASSWORD', 'Specify database password') do |db_password|
            @options.password = db_password
          end

          opts.on('-n', '--db-encoding=DB_ENCODING', 'Specify database encoding, default is utf8') do |db_encoding|
            @options.encoding = db_encoding
          end

          opts.on('-o', '--db-pool=DB_POOL', 'Specify database pool size, default is 5') do |db_pool|
            @options.pool = db_pool
          end

          opts.on('-HSSH_HOST', '--ssh-host=SSH_HOST', 'Specify SSH host') do |ssh_host|
            @options.ssh[:host] = ssh_host
          end

          opts.on('-OSSH_PORT', '--ssh-port=SSH_PORT', 'Specify SSH port') do |ssh_port|
            @options.ssh[:port] = ssh_port.to_i
          end

          opts.on('-USSH_USER', '--ssh-user=SSH_USER', 'Specify SSH user') do |ssh_user|
            @options.ssh[:user] = ssh_user
          end

          opts.on('-WSSH_PASSWORD', '--ssh-password=SSH_PASSWORD', 'Specify SSH password') do |ssh_password|
            @options.ssh[:password] = ssh_password
          end

          opts.on('-LSSH_LOCAL_PORT', '--ssh-local-port=SSH_LOCAL_PORT', 'Specify local SSH proxy port') do |local_port|
            @options.ssh[:local_port] = local_port.to_i
          end

          opts.on('-ECODE', '--eval=CODE', 'evaluate CODE') do |code|
            @options.code = code
          end

          opts.on('-S', '--show-sql', 'Show SQL on STDOUT') do
            @options.show_sql = true
          end

          opts.on('-wOUTOUT', '--write-sql=OUTPUT', 'Write SQL to OUTPUT file') do |file|
            @options.write_sql = file
          end

          opts.on('-AOUTPUT', '--append-sql=OUTPUT', 'Append SQL to OUTPUT file') do |file|
            @options.append_sql = file
          end

          opts.on('', '--help', 'Prints this help') do
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
        conf = File.expand_path('~/.arql.d/init.yml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql.d/init.yaml')
        return conf if File.file?(conf)
      end

      def default_initializer
        conf = File.expand_path('~/.arql.yml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql.yaml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql.d/init.yml')
        return conf if File.file?(conf)
        conf = File.expand_path('~/.arql.d/init.yaml')
        return conf if File.file?(conf)
      end
    end
  end
end
