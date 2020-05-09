module Arql
  module Extension
    extend ActiveSupport::Concern

    def to_insert_sql
      self.class.to_insert_sql([self])
    end

    def to_upsert_sql
      self.class.to_upsert_sql([self])
    end

    class_methods do
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
    end
  end

  class Definition
    class << self
      def models
        @@models ||= []
      end
    end

    def initialize
      @@models = []
      ActiveRecord::Base.connection.tap do |conn|
        conn.tables.each do |table_name|
          conn.primary_key(table_name).tap do |pkey|
            table_name.camelize.tap do |const_name|
              const_name = 'Modul' if const_name == 'Module'
              const_name = 'Clazz' if const_name == 'Class'
              Class.new(ActiveRecord::Base) do
                include Arql::Extension
                self.primary_key = pkey
                self.table_name = table_name
                self.inheritance_column = nil
                self.default_timezone = :local
              end.tap do |clazz|
                Object.const_set(const_name, clazz).tap do |const|
                  const_name.gsub(/[a-z]*/, '').tap do |abbr|
                    unless Object.const_defined?(abbr)
                      Object.const_set abbr, const
                      abbr_const = abbr
                    end

                    @@models << {
                      model: const,
                      abbr: abbr_const,
                      table: table_name
                    }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
