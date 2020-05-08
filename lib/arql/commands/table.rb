require 'terminal-table'

module Arql::Commands
  module Table
    class << self
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

    Pry.commands.block_command 'table' do |table_name|
      puts
      puts Table::table_info(table_name)
    end

    Pry.commands.alias_command 't', 'table'
  end
end
