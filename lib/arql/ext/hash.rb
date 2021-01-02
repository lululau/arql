class Hash
  def write_excel(filename)
    generate_excel(filename) do |workbook|
      each do |sheet_name, sheet_data|
        workbook.add_worksheet(name: sheet_name) do |sheet|
          if sheet_data.is_a?(Hash)
            fields = sheet_data[:fields].map(&:to_s)
            sheet.add_row(fields, types: [:string] * fields.size)
            sheet_data[:data].each do |row|
              sheet.add_row(row.slice(*fields).values.map(&:to_s), types: [:string] * fields.size)
            end
          end

          if sheet_data.is_a?(Array)
            if sheet_data.size > 0 && sheet_data.first.is_a?(ActiveModel::Base)
              fields = sheet_data.first.attributes.keys
              sheet.add_row(fields, types: [:string] * fields.size)
              sheet_data.each do |row|
                sheet.add_row(row.slice(*fields).values.map(&:to_s), types: [:string] * fields.size)
              end
            end

            if sheet_data.size > 0 && sheet_data.first.is_a?(Hash)
              fields = sheet_data.first.keys
              sheet.add_row(fields, types: [:string] * fields.size)
              sheet_data.each do |row|
                sheet.add_row(row.slice(*fields).values.map(&:to_s), types: [:string] * fields.size)
              end
            end

            if sheet_data.size > 0 && sheet_data.first.is_a?(Array)
              sheet_data.each do |row|
                sheet.add_row(row.map(&:to_s), types: [:string] * fields.size)
              end
            end
          end
        end
      end
    end
  end
end
