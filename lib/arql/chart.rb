require 'chartkick'

module Arql
  module Chart
    include Chartkick::Helper

    def line_chart(data_source, **options)
      html_chart "LineChart", data_source, **options
    end

    def pie_chart(data_source, **options)
      html_chart "PieChart", data_source, **options
    end

    def column_chart(data_source, **options)
      html_chart "ColumnChart", data_source, **options
    end

    def bar_chart(data_source, **options)
      html_chart "BarChart", data_source, **options
    end

    def area_chart(data_source, **options)
      html_chart "AreaChart", data_source, **options
    end

    def scatter_chart(data_source, **options)
      html_chart "ScatterChart", data_source, **options
    end

    def geo_chart(data_source, **options)
      html_chart "GeoChart", data_source, **options
    end

    def timeline(data_source, **options)
      html_chart "Timeline", data_source, **options
    end

    def html_chart(klass, data_source, **options)
      chart = chartkick_chart(klass, data_source, **options)

      html = <<~HTML
        <html>
          <head>
            <script src="https://www.hackit.fun/js/Chart.bundle.js"></script>
            <script src="https://www.hackit.fun/js/chartkick.js"></script>
          </head>
          <body style="color: red">
            #{chart}
          </body>
        </html>
      HTML
      html = html.lines.reject {|line| line =~ /(data-turbo)|(Chartkick" in window)|(^\s*\}\s*else\s*\{\s*$)|(chartkick:load)|(^\s*\}\s*$)/}.join("\n")
      IRuby.display(html, mime: 'text/html')
    end
  end
end