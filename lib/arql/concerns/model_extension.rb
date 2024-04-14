module Arql
  module Extension
    extend ActiveSupport::Concern

    def v(compact: false)
      t = []
      t << ['Attribute Name', 'Attribute Value', 'SQL Type', 'Comment']
      t << nil
      self.class.connection.columns(self.class.table_name).each do |column|
        value = read_attribute(column.name)
        if compact && value.blank?
          next
        end
        t << [column.name, value, column.sql_type, column.comment || '']
      end
      t
    end

    def t(compact: false, format: :terminal)
      puts Terminal::Table.new { |t|
        t.style = self.class.table_style_for_format(format)
        v(compact: compact).each { |row| t << (row || :separator) }
      }.try { |e|
        case format
        when :md
          e.to_s.lines.map { |l| '  ' + l }.join
        when :org
          e.to_s.lines.map { |l| '  ' + l.gsub(/^\+|\+$/, '|') }.join
        else
          e.to_s
        end
      }
    end

    def vd(compact: false)
      VD.new do |vd|
        vd << ['Attribute Name', 'Attribute Value', 'SQL Type', 'Comment']
        self.class.connection.columns(self.class.table_name).each do |column|
          value = read_attribute(column.name)
          next if compact && value.blank?

          vd << [column.name, read_attribute(column.name), column.sql_type, column.comment || '']
        end
      end
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

      def v
        t = [['PK', 'Name', 'SQL Type', 'Ruby Type', 'Limit', 'Precision', 'Scale', 'Default', 'Nullable', 'Comment']]
        t << nil
        columns.each do |column|
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

      def t(format: :terminal)
        heading_prefix = case format
        when :md
          '# '
        when :org
          '* '
        when :sql
          '-- '
        end
        puts "\n#{heading_prefix}Table: #{table_name}\n\n"
        if format == :sql
          puts to_create_sql + ';'
        else
          puts(Terminal::Table.new { |t|
            t.style = self.table_style_for_format(format)
            v.each { |row| t << (row || :separator) }
          }.try { |e|
            case format
            when :md
              e.to_s.lines.map { |l| '  ' + l }.join
            when :org
              e.to_s.lines.map { |l| '  ' + l.gsub(/^\+|\+$/, '|') }.join
            else
              e.to_s
            end
          })
        end
      end

      def vd
        VD.new do |vd|
          v.each do |row|
            vd << row if row
          end
        end
        nil
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
        superclass.definition.connection.exec_query("show create table `#{table_name}`").rows.last.last
      end

      def dump(filename, no_create_table=false)
        Arql::Mysqldump.new(superclass.definition.options).dump_table(filename, table_name, no_create_table)
      end

      def table_style_for_format(format)
        case format.to_s
        when 'md'
          {
            border_top: false,
            border_bottom: false,
            border_i: '|'
          }
        when 'org'
          {
            border_top: false,
            border_bottom: false,
          }
        else
          {}
        end
      end
    end
  end
end
