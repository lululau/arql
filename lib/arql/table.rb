require 'terminal-table'

module Arql
  class Table
    attr_accessor :caption, :headers, :body
    def initialize(caption=nil, headers=[], body=[])
      @headers = headers
      @body = body
      @caption = caption
      yield(self) if block_given?
    end

    def to_iruby
      IRuby.display(to_html, mime: 'text/html')
    end

    def to_terminal(format='terminal')
      tbl = Terminal::Table.new do |t|
        t.style = terminal_style_for_format(format)
        t << headers || []
        t << :separator
        (body || []).each { |row| t << row }
      end

      title = @caption.try do |c|
        "#{c}\n---------------------------------------\n\n"
      end || ''

      table = case format.to_s
      when 'md'
        tbl.to_s.lines.map { |l| '  ' + l }.join
      when 'org'
        tbl.to_s.lines.map { |l| '  ' + l.gsub(/^\+|\+$/, '|') }.join
      else
        tbl.to_s
      end

      terminal_width = `tput cols`.to_i
      table_lines = table.lines.map(&:chomp)
      if table_lines.first.size > terminal_width
        title + (table_lines[0..2] || []).join("\n") + "\n" + (table_lines[3..-1] || []).join("\n#{'-' * terminal_width}\n")
      else
        title + table
      end

    end

    def terminal_style_for_format(format)
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

    def to_html
      html = "<table style='border-collapse: collapse; font-family: JetBrains Mono, Source Code Pro, Ubuntu Mono, Monaco, Menlo, Courier New'>"
      html << "<caption style='text-align: left;'>#{@caption}</caption>" if @caption.present?
      html << "<thead><tr>"
      (@headers || []).each do |h|
        html << "<th style='text-align: left; white-space: nowrap;'>#{h}</th>"
      end
      html << "</tr></thead>"
      html << "<tbody>"
      (@body || []).each do |row|
        html << "<tr>"
        row.each do |r|
          html << "<td style='text-align: left; white-space: nowrap;'>#{r}</td>"
        end
        html << "</tr>"
      end
      html << "</tbody>"
      html << "</table>"
    end
  end
end