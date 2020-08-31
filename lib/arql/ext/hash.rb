class Hash
  def write_excel(filename)
    generate_excel(filename) do |workbook|
      each do |sheet_name, sheet_data|
        workbook.add_worksheet(name: sheet_name) do |sheet|
          if sheet_data.is_a?(Hash) && sheet_data[:fields].present?
              fields = sheet_data[:fields].map(&:to_s)
            else
              fields = sheet_data[:data].first.attributes.keys
            end
            sheet.add_row(fields, types: [:string] * fields.size)
            sheet_data = sheet_data[:data]
          end
          sheet_data.each do |row|
            if row.is_a?(Array)
              sheet.add_row(row.map(&:to_s), types: [:string] * row.size)
            else
              sheet.add_row(row.slice(fields).values.map(&:to_s), types: [:string] * fields.size)
            end
          end
        end
      end
    end
  end
end
