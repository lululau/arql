require 'arql/vd'

module Arql::Commands
  module VD
    class << self
      def get_table_name(name)
        name = name.to_s
        return name if name =~ /^[a-z]/
        if Object.const_defined?(name)
          klass = Object.const_get(name)
          return klass.table_name if klass < ActiveRecord::Base
        end
        name
      end

      def table_info_vd(table_name)
        Arql::VD.new do |vd|
          table_info(table_name).each { |row| vd << row }
        end
      end

      def table_info(table_name)
        t = []
        t << ['PK', 'Name', 'SQL Type', 'Ruby Type', 'Limit', 'Precision', 'Scale', 'Default', 'Nullable', 'Comment']
        connection = ::ActiveRecord::Base.connection
        connection.columns(table_name).each do |column|
          pk = if [connection.primary_key(table_name)].flatten.include?(column.name)
                 'Y'
               else
                 ''
               end
          t << [pk, column.name, column.sql_type,
                column.sql_type_metadata.type, column.sql_type_metadata.limit || '',
                column.sql_type_metadata.precision || '', column.sql_type_metadata.scale || '', column.default || '',
                column.null, column.comment || '']
        end
        t
      end
    end

    Pry.commands.block_command 'vd' do |name|
      table_name = VD::get_table_name(name)
      VD::table_info_vd(table_name)
    end
  end
end
