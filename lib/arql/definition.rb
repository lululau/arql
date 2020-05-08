module Arql
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
                self.primary_key = pkey
                self.table_name = table_name
                self.inheritance_column = nil
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
