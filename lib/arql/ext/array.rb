class Array
  def to_insert_sql(batch_size=500)
    raise 'All element should be an ActiveRecord instance object' unless all? { |e| e.is_a?(ActiveRecord::Base) }
    group_by(&:class).map do |(klass, records)|
      klass.to_insert_sql(records, batch_size)
    end.join("\n")
  end

  def to_upsert_sql(batch_size=500)
    raise 'All element should be an ActiveRecord instance object' unless all? { |e| e.is_a?(ActiveRecord::Base) }
    group_by(&:class).map do |(klass, records)|
      klass.to_upsert_sql(records, batch_size)
    end.join("\n")
  end

  def t(*attrs, **options)
    if (attrs.present? || options.present? && options[:except]) && present? && first.is_a?(ActiveRecord::Base)
      column_names = first.attribute_names.map(&:to_sym)
      attrs = attrs.flat_map { |e| e.is_a?(Regexp) ? column_names.grep(e) : e }.uniq
      if options.present? && options[:except]
        attrs = column_names if attrs.empty?
        if options[:except].is_a?(Regexp)
          attrs.reject! { |e| e =~ options[:except] }
        else
          attrs -= [options[:except]].flatten
        end
      end
      puts Terminal::Table.new { |t|
        t << attrs
        t << :separator
        each do |e|
          t << e.attributes.values_at(*attrs.map(&:to_s))
        end
      }
    else
      table = Terminal::Table.new { |t|
        v.each { |row| t << (row || :separator)}
      }.to_s

      terminal_width = `tput cols`.to_i
      if table.lines.first.size > terminal_width
        table = table.lines.map(&:chomp)
        puts table[0..2].join("\n")
        puts table[3..-1].join("\n#{'-' * terminal_width}\n")
      else
        puts table
      end
    end
  end

  def v
    return self unless present?
    t = []
    if map(&:class).uniq.size == 1
      if first.is_a?(ActiveRecord::Base)
        t << first.attribute_names
        t << nil
        each do |e|
          t << e.attributes.values_at(*first.attribute_names).map(&:as_json)
        end
      elsif first.is_a?(Array)
        t = map { |a| a.map(&:as_json) }
      elsif first.is_a?(Hash) || first.is_a?(ActiveSupport::HashWithIndifferentAccess)
        t << first.keys
        t << nil
        each do |e|
          t << e.values_at(*first.keys).map(&:as_json)
        end
      else
        return self
      end
    end
    t
  end

  def write_csv(filename, *fields, **options)
    generate_csv(filename, **options) do |csv|
      if size > 0 && first.is_a?(ActiveRecord::Base)
        if fields.empty?
          fields = first.attributes.keys
        else
          fields = fields.map(&:to_s)
        end
        csv << fields
      end
      if size > 0 && first.is_a?(Hash)
        if fields.empty?
          fields = first.keys
        end
        csv << fields
      end
      each do |row|
        if row.is_a?(Array)
          csv << row.map(&:to_s)
        else
          csv << row.slice(*fields).values.map(&:to_s)
        end
      end
    end
  end

  def write_excel(filename, *fields, **options)
    sheet_name = options[:sheet_name] || 'Sheet1'
    generate_excel(filename) do |workbook|
      workbook.add_worksheet(name: sheet_name) do |sheet|
        if size > 0 && first.is_a?(ActiveRecord::Base)
          if fields.empty?
            fields = first.attributes.keys
          else
            fields = fields.map(&:to_s)
          end
          sheet.add_row(fields, types: [:string] * fields.size)
        end
        if size > 0 && first.is_a?(Hash)
          if fields.empty?
            fields = first.keys
          end
          sheet.add_row(fields, types: [:string] * fields.size)
        end
        each do |row|
          if row.is_a?(Array)
            sheet.add_row(row.map(&:to_s), types: [:string] * row.size)
          else
            sheet.add_row(row.slice(*fields).values.map(&:to_s), types: [:string] * fields.size)
          end
        end
      end
    end
  end

  def dump(filename, batch_size=500)
    File.open(File.expand_path(filename), 'w') do |file|
      group_by(&:class).each do |(klass, records)|
        file.puts(klass.to_upsert_sql(records, batch_size))
      end
    end
    {size: size, file: File.expand_path(filename)}
  end
end
