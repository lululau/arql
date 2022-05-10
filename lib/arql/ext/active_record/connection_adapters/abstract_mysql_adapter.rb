require 'active_record/connection_adapters/abstract_mysql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter

      def extract_schema_qualified_name_of_tables(table_names)
        table_names.map do |string|
          schema, name = string.to_s.scan(/[^`.\s]+|`[^`]*`/)
          schema, name = nil, schema unless name
          [schema, name]
        end
      end

      def quoted_scope_of_tables(names = nil)
        extract_schema_qualified_name_of_tables(names).map do |(schema, name)|
          scope = {}
          scope[:schema] = schema ? quote(schema) : "database()"
          scope[:name] = quote(name) if name
          scope
        end
      end

      def primary_keys_of_tables(table_names) # :nodoc:
        raise ArgumentError unless table_names.present?

        scopes = quoted_scope_of_tables(table_names)

        res = query(<<~SQL, "SCHEMA")
        SELECT table_name, column_name
        FROM information_schema.statistics
        WHERE index_name = 'PRIMARY'
        AND (table_schema, table_name) in
        (#{scopes.map { |scope| "(#{scope[:schema]}, #{scope[:name]})" }.join(', ')})
          ORDER BY seq_in_index
        SQL

        res.group_by(&:first).map { |table, vlaues| [table, vlaues.map(&:last)] }.to_h
      end

      def table_comment_of_tables(table_names) # :nodoc:
        scopes = quoted_scope_of_tables(table_names)

        query(<<~SQL, "SCHEMA").presence.try(&:to_h)
        SELECT table_name, table_comment
        FROM information_schema.tables
        WHERE (table_schema, table_name) in
        (#{scopes.map { |scope| "(#{scope[:schema]}, #{scope[:name]})" }.join(', ')})
        SQL
      end
    end
  end
end
