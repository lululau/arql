module Arql
  class Mysqldump

    def initialize(options = nil)
      @options = options
      if options[:socket]
        port_or_sock = "-S #{options[:socket]}"
      else
        port_or_sock = "-P #{options[:port] || 3306}"
      end
      @base_dump_cmd = "mysqldump -u %{user} -h %{host} %{port_or_sock} %{password} --skip-lock-tables " % {
        user: options[:username],
        host: options[:host],
        password: options[:password].presence.try { |e| "-p#{e}" } || '',
        port_or_sock: port_or_sock
      }
    end

    def dump_table(filename, table_name, no_create_table = false)
      system dump_table_cmd(table_name, no_create_table) + " > #{filename}"
    end

    def dump_database(filename, no_create_db = false)
      system dump_database_cmd(no_create_db) + " > #{filename}"
    end

    def dump_table_cmd(table_name, no_create_table = false)
      @base_dump_cmd + " " + if no_create_table
                               "--no-create-info #{@options[:database]} #{table_name}"
                             else
                               "--add-drop-table #{@options[:database]} #{table_name}"
                             end
    end

    def dump_database_cmd(no_create_db = false)
      @base_dump_cmd + " " + if no_create_db
                               "--no-create-db --add-drop-database --databases #{@options[:database]}"
                             else
                               "--add-drop-database --add-drop-table --databases #{@options[:database]}"
                             end
    end
  end
end
