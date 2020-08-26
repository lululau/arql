module Kernel
  def sql(sql)
    ActiveRecord::Base.connection.exec_query(sql)
  end

  def print_tables(format = :md)
    require 'terminal-table'

    tables = ActiveRecord::Base.connection.tables.map do |table_name|
      {
        table: table_name,
        table_comment: ActiveRecord::Base.connection.table_comment(table_name) || '',
        columns: ::ActiveRecord::Base.connection.columns(table_name)
      }
    end

    outputs = tables.map do |table|
      table_name = table[:table]
      table_comment = table[:table_comment]
      case format
      when :md
        "# #{table_name} #{table_comment}\n\n" +
          Terminal::Table.new { |t|
          t.headings = ['PK', 'Name', 'SQL Type', 'Limit', 'Precision', 'Scale', 'Default', 'Nullable', 'Comment']
          t.rows = table[:columns].map { |column|
            pk = if column.name == ::ActiveRecord::Base.connection.primary_key(table_name)
                   'Y'
                 else
                   ''
                 end
            [pk, "`#{column.name}`", column.sql_type, column.sql_type_metadata.limit || '', column.sql_type_metadata.precision || '',
             column.sql_type_metadata.scale || '', column.default || '', column.null, column.comment || '']
          }
          t.style = {
            border_top: false,
            border_bottom: false,
            border_i: '|'
          }
        }.to_s.lines.map { |l| '  ' + l }.join
      when :org
        "* #{table_name} #{table_comment}\n\n" +
          Terminal::Table.new { |t|
          t.headings = ['PK', 'Name', 'SQL Type', 'Limit', 'Precision', 'Scale', 'Default', 'Nullable', 'Comment']
          t.rows = table[:columns].map { |column|
            pk = if column.name == ::ActiveRecord::Base.connection.primary_key(table_name)
                   'Y'
                 else
                   ''
                 end
            [pk, "=#{column.name}=", column.sql_type, column.sql_type_metadata.limit || '', column.sql_type_metadata.precision || '',
             column.sql_type_metadata.scale || '', column.default || '', column.null, column.comment || '']
          }
          t.style = {
            border_top: false,
            border_bottom: false,
          }
        }.to_s.lines.map { |l| '  ' + l.gsub(/^\+|\+$/, '|') }.join
      when :sql
        "-- Table: #{table_name}\n\n" + ActiveRecord::Base.connection.exec_query("show create table `#{table_name}`").rows.last.last + ';'
      end
    end

    outputs.each { |out| puts out; puts }
  end
end
