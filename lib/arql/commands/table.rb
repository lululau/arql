require 'terminal-table'

module Arql::Commands
  module Table
    class << self
      def get_table_name(name)
        return name if name =~ /^[a-z]/
        if Object.const_defined?(name)
          klass = Object.const_get(name)
          return klass.table_name if klass < ActiveRecord::Base
        end
        name
      end

      def table_info(table_name)
        Terminal::Table.new do |t|
          t << ['PK', 'Name', 'SQL Type', 'Ruby Type', 'Limit', 'Precision', 'Scale', 'Default', 'Nullable', 'Comment']
          t << :separator
          connection = ::ActiveRecord::Base.connection
          connection.columns(table_name).each do |column|
            pk = if column.name == connection.primary_key(table_name)
                    'Y'
                  else
                    ''
                  end
            t << [pk, column.name, column.sql_type,
                  column.sql_type_metadata.type, column.sql_type_metadata.limit || '',
                  column.sql_type_metadata.precision || '', column.sql_type_metadata.scale || '', column.default || '',
                  column.null, column.comment || '']
          end
        end
      end
    end

    Pry.commands.block_command 'table' do |name|
      table_name = Table::get_table_name(name)
      puts
      puts "Table: #{table_name}"
      puts Table::table_info(table_name)
    end

    Pry.commands.alias_command 't', 'table'
  end
end
