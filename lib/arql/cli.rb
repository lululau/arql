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
        @options = OpenStruct.new(config_file: default_config_file,
                                  initializer: default_initializer,
                                  ssh: {})


        OptionParser.new do |opts|
          opts.banner = <<~EOF
          Usage: arql [options] [ruby file]

            If neither [ruby file] nor -e option specified, and STDIN is a tty, a Pry REPL will be launched,
            otherwise the specified ruby file or -e option value or ruby code read from STDIN will be run, and no REPL launched

          EOF

          opts.on('-cCONFIG_FILE', '--conf=CONFIG_FILE', 'Specify config file, default is $HOME/.arql.yml, or $HOME/.arql.d/init.yml.') do |config_file|
            @options.config_file = config_file
          end

          opts.on('-iINITIALIZER', '--initializer=INITIALIZER', 'Specify initializer ruby file, default is $HOME/.arql.rb, or $HOME/.arql.d/init.rb.') do |initializer|
            @options.initializer = initializer
          end

          opts.on('-eENVIRON', '--env=ENVIRON', 'Specify config environment, multiple environments allowed, separated by comma') do |env_names|
            @options.environments = env_names.split(/[,\+:]/)
            if @options.environments.any? { |e| e =~ /^default|arql$/i }
              warn '[default, arql] are reserved environment names, please use another name'
              exit(1)
            end
          end

          opts.on('-aDB_ADAPTER', '--db-adapter=DB_ADAPTER', 'Specify database Adapter, default is sqlite3') do |db_adapter|
            @options.adapter = db_adapter
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

          opts.on('-V', '--version', 'Prints version') do
            puts "ARQL #{Arql::VERSION}"
            exit
          end

          opts.on('', '--help', 'Prints this help') do
            puts opts
            exit
          end

        end.parse!

        @options.args = ARGV

        if @options.environments&.size&.positive? && any_database_options?
          $stderr.puts "Following options are not allowed when using multiple environments specified: #{database_options.join(', ')}"
          $stderr.puts "    #{database_options.join(', ')}"
          exit(1)
        end
      end

      def any_database_options?
        %i[adapter host port database username
           password encoding pool ssh].reduce(false) do |acc, opt|
          acc || @options.send(opt).present?
        end
      end

      def database_options
        ['--db-adapter', '--db-host', '--db-port', '--db-name', '--db-user', '--db-password',
         '--db-encoding', '--db-pool', '--ssh-host', '--ssh-port', '--ssh-user', '--ssh-password', '--ssh-local-port']
      end

      def default_config_file
        ['~/.arql.yml', '~/.arql.yaml', '~/.arql.d/init.yml', '~/.arql.d/init.yaml'].find { |f|
          File.file?(File.expand_path(f))
        }.try { |f| File.expand_path(f) }
      end

      def default_initializer
        ['~/.arql.rb', '~/.arql.d/init.rb',].find { |f|
          File.file?(File.expand_path(f))
        }.try { |f| File.expand_path(f) }
      end
    end
  end
end
