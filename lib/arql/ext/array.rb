require 'arql/vd'
require 'youplot'

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
      # if options[:compact]
      #   attrs = attrs.select { |e| any { |r| r.attributes[e.to_s]&.present? } }
      # end
      puts Terminal::Table.new { |t|
        t << attrs
        t << :separator
        each do |e|
          t << e.attributes.values_at(*attrs.map(&:to_s))
        end
      }
    else
      table = Terminal::Table.new { |t|
        v(**options).each { |row| t << (row || :separator)}
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

  def vd(*attrs, **options)
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

      Arql::VD.new do |vd|
        vd << attrs
        each do |e|
          vd << e.attributes.values_at(*attrs.map(&:to_s))
        end
      end
    else
      Arql::VD.new do |vd|
        v.each { |row| vd << row if row }
      end
    end
    nil
  end

  def v(**options)
    return self unless present?
    t = []
    if map(&:class).uniq.size == 1
      if first.is_a?(ActiveRecord::Base)
        attribute_names = first.attribute_names
        if options[:compact]
          attribute_names = attribute_names.select { |e| any? { |r| r.attributes[e]&.present? } }
        end
        t << attribute_names
        t << nil
        each do |e|
          t << e.attributes.values_at(*attribute_names).map(&:as_json)
        end
      elsif first.is_a?(Array)
        t = map { |a| a.map(&:as_json) }
      elsif first.is_a?(Hash) || first.is_a?(ActiveSupport::HashWithIndifferentAccess)
        keys = first.keys
        if options[:compact]
          keys = keys.select { |e| any? { |r| r[e]&.present? } }
        end
        t << keys
        t << nil
        each do |e|
          t << e.values_at(*keys).map(&:as_json)
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

  %i[bar barplot countplot hist histo line lineplot lines lineplots scatter density box boxplot].each do |type|
    define_method(type) do |*args|
      plot_backend = YouPlot::Backends::UnicodePlot
      params = Struct.new(:title, :width, :height, :border, :margin, :padding, :color, :xlabel,
          :ylabel, :labels, :symbol, :xscale, :nbins, :closed, :canvas, :xlim, :ylim, :grid, :name) do
        def to_hc
          {}
        end
      end.new
      fmt = 'xyy'
      raw_data = map do |e|
        if e.is_a?(Array)
          e
        else
          [e]
        end
      end
      transposed = Array.new(raw_data.map(&:length).max) { |i| raw_data.map { |e| e[i] } }
      data = Struct.new(:headers, :series).new(nil, transposed)
      plot = case type
        when :bar, :barplot
          plot_backend.barplot(data, params, fmt)
        when :countplot
          plot_backend.barplot(data, params, count: true, reverse: false)
        when :hist, :histo
          plot_backend.histogram(data, params)
        when :line, :lineplot
          plot_backend.line(data, params, fmt)
        when :lines, :lineplots
          plot_backend.lines(data, params, fmt)
        when :scatter
          plot_backend.scatter(data, params, fmt)
        when :density
          plot_backend.density(data, params, fmt)
        when :box, :boxplot
          plot_backend.boxplot(data, params)
        else
          raise "unrecognized plot_type: #{type}"
        end
      plot.render(STDOUT)
    end
  end
end
