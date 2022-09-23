require 'arql/concerns'
module Kernel
  CSV_BOM = "\xef\xbb\xbf"

  include ::Arql::Concerns::GlobalDataDefinition

  def q(sql)
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
            pk = if [::ActiveRecord::Base.connection.primary_key(table_name)].flatten.include?(column)
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
            pk = if [::ActiveRecord::Base.connection.primary_key(table_name)].flatten.include?(column)
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

  def generate_csv(filename, **options, &block)
    opts = {
      col_sep: "\t",
      row_sep: "\r\n"
    }
    opts.merge!(options.except(:encoding))
    encoding = options[:encoding] || 'UTF-16LE'
    File.open(File.expand_path(filename), "w:#{encoding}") do |file|
      file.write(CSV_BOM)
      file.write CSV.generate(**opts, &block)
    end
  end

  def parse_csv(filename, **options)
    encoding = options[:encoding] || 'UTF-16'
    opts = {
      headers: false,
      col_sep: "\t",
      row_sep: "\r\n"
    }
    opts.merge!(options.except(:encoding))
    CSV.parse(IO.read(File.expand_path(filename), encoding: encoding, binmode: true).encode('UTF-8'), **opts).to_a
  end

  def generate_excel(filename)
    Axlsx::Package.new do |package|
      yield(package.workbook)
      package.serialize(File.expand_path(filename))
    end
  end

  def parse_excel(filename)
    xlsx = Roo::Excelx.new(File.expand_path(filename))
    xlsx.sheets.each_with_object({}) do |sheet_name, result|
      begin
        result[sheet_name] = xlsx.sheet(sheet_name).to_a
      rescue
      end
    end
  end

end
