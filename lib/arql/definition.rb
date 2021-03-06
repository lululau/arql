require 'arql/concerns'
module Arql
  module Extension
    extend ActiveSupport::Concern

    def t
      puts Terminal::Table.new { |t|
        v.each { |row| t << (row || :separator) }
      }
    end

    def v
      t = []
      t << ['Attribute Name', 'Attribute Value', 'SQL Type', 'Comment']
      t << nil
      self.class.connection.columns(self.class.table_name).each do |column|
        t << [column.name, read_attribute(column.name), column.sql_type, column.comment || '']
      end
      t
    end

    def to_insert_sql
      self.class.to_insert_sql([self])
    end

    def to_upsert_sql
      self.class.to_upsert_sql([self])
    end

    def write_csv(filename, *fields, **options)
      [self].write_csv(filename, *fields, **options)
    end

    def write_excel(filename, *fields, **options)
      [self].write_excel(filename, *fields, **options)
    end

    def dump(filename, batch_size=500)
      [self].dump(filename, batch_size)
    end

    included do
    end

    class_methods do
      def t
        table_name = Commands::Table::get_table_name(name)
        puts "\nTable: #{table_name}"
        puts Commands::Table::table_info_table(table_name)
      end

      def v
        table_name = Commands::Table::get_table_name(name)
        Commands::Table::table_info(table_name)
      end
      def to_insert_sql(records, batch_size=1)
        to_sql(records, :skip, batch_size)
      end

      def to_upsert_sql(records, batch_size=1)
        to_sql(records, :update, batch_size)
      end

      def to_sql(records, on_duplicate, batch_size)
        records.in_groups_of(batch_size, false).map do |group|
          ActiveRecord::InsertAll.new(self, group.map(&:attributes), on_duplicate: on_duplicate).send(:to_sql) + ';'
        end.join("\n")
      end

      def to_create_sql
        ActiveRecord::Base.connection.exec_query("show create table #{table_name}").rows.last.last
      end

      def dump(filename, no_create_table=false)
        Arql::Mysqldump.new.dump_table(filename, table_name, no_create_table)
      end
    end
  end

  class Definition
    class << self
      def models
        @@models ||= []
      end

      def redefine
        options = @@options
        @@models.each do |model|
          Object.send :remove_const, model[:model].name.to_sym if model[:model]
          Object.send :remove_const, model[:abbr].to_sym if model[:abbr]
        end
        @@models = []
        ActiveRecord::Base.connection.tap do |conn|
          conn.tables.each do |table_name|
            table_comment = conn.table_comment(table_name)
            conn.primary_key(table_name).tap do |pkey|
              table_name.camelize.tap do |const_name|
                const_name = 'Modul' if const_name == 'Module'
                const_name = 'Clazz' if const_name == 'Class'
                Class.new(::ArqlModel) do
                  include Arql::Extension
                  if pkey.is_a?(Array)
                    self.primary_keys = pkey
                  else
                    self.primary_key = pkey
                  end
                  self.table_name = table_name
                  self.inheritance_column = nil
                  self.default_timezone = :local
                  if options[:created_at].present?
                    define_singleton_method :timestamp_attributes_for_create do
                      options[:created_at]
                    end
                  end

                  if options[:updated_at].present?
                    define_singleton_method :timestamp_attributes_for_update do
                      options[:updated_at]
                    end
                  end
                end.tap do |clazz|
                  Object.const_set(const_name, clazz).tap do |const|
                    const_name.gsub(/[a-z]*/, '').tap do |bare_abbr|
                      abbr_const = nil
                      9.times do |idx|
                        abbr = idx.zero? ? bare_abbr : "#{bare_abbr}#{idx+1}"
                        unless Object.const_defined?(abbr)
                          Object.const_set abbr, const
                          abbr_const = abbr
                          break
                        end
                      end

                      @@models << {
                        model: const,
                        abbr: abbr_const,
                        table: table_name,
                        comment: table_comment
                      }
                    end
                  end
                end
              end
            end
          end
        end

        App.instance&.load_initializer!
      end
    end

    def initialize(options)
      @@options = options
      @@models = []
      ActiveRecord::Base.connection.tap do |conn|
        Object.const_set('ArqlModel', Class.new(ActiveRecord::Base) do
                           include ::Arql::Concerns::TableDataDefinition
                           self.abstract_class = true

                           define_singleton_method(:indexes) do
                             conn.indexes(table_name).map do |idx|
                               {
                                 Table: idx.table,
                                 Name: idx.name,
                                 Columns: idx.columns.join(', '),
                                 Unique: idx.unique,
                                 Comment: idx.comment
                               }
                             end.t
                           end
                         end)
        conn.tables.each do |table_name|
          table_comment = conn.table_comment(table_name)
          conn.primary_key(table_name).tap do |pkey|
            table_name.camelize.tap do |const_name|
              const_name = 'Modul' if const_name == 'Module'
              const_name = 'Clazz' if const_name == 'Class'
              Class.new(::ArqlModel) do
                include Arql::Extension
                if pkey.is_a?(Array)
                  self.primary_keys = pkey
                else
                  self.primary_key = pkey
                end
                self.table_name = table_name
                self.inheritance_column = nil
                self.default_timezone = :local
                if options[:created_at].present?
                  define_singleton_method :timestamp_attributes_for_create do
                    options[:created_at]
                  end
                end

                if options[:updated_at].present?
                  define_singleton_method :timestamp_attributes_for_update do
                    options[:updated_at]
                  end
                end
              end.tap do |clazz|
                Object.const_set(const_name, clazz).tap do |const|
                  const_name.gsub(/[a-z]*/, '').tap do |bare_abbr|
                    abbr_const = nil
                    9.times do |idx|
                      abbr = idx.zero? ? bare_abbr : "#{bare_abbr}#{idx+1}"
                      unless Object.const_defined?(abbr)
                        Object.const_set abbr, const
                        abbr_const = abbr
                        break
                      end
                    end

                    @@models << {
                      model: const,
                      abbr: abbr_const,
                      table: table_name,
                      comment: table_comment
                    }
                  end
                end
              end
            end
          end
        end
      end
    end

    ::ActiveRecord::Relation.class_eval do
      def t(*attrs, **options)
        records.t(*attrs, **options)
      end

      def v
        records.v
      end

      def a
        to_a
      end

      def write_csv(filename, *fields, **options)
        records.write_csv(filename, *fields, **options)
      end

      def write_excel(filename, *fields, **options)
        records.write_excel(filename, *fields, **options)
      end

      def dump(filename, batch_size=500)
        records.dump(filename, batch_size)
      end
    end
  end
end
