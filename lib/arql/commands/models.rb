require 'terminal-table'

module Arql::Commands
  module Models
    class << self
      def models
        t = []
        t << ['Table Name', 'Model Class', 'Abbr', 'Comment']
        t << nil
        Arql::Definition.models.each do |definition|
          t << [definition[:table], definition[:model].name, definition[:abbr] || '', definition[:comment] || '']
        end
        t
      end

      def models_table(table_regexp=nil, column_regexp=nil)
        if column_regexp.nil?
          Terminal::Table.new do |t|
            models.each_with_index { |row, idx| t << (row || :separator) if row.nil? ||
              table_regexp.nil? ||
              idx.zero? ||
              row.any? { |e| e =~ table_regexp }
            }
          end
        else
          connection = ::ActiveRecord::Base.connection
          table = Terminal::Table.new do |t|
            t << ['PK', 'Table', 'Model', 'Name', 'SQL Type', 'Ruby Type', 'Limit', 'Precision', 'Scale', 'Default', 'Nullable', 'Comment']
            t << :separator
            Arql::Definition.models.each do |definition|
              model_class = definition[:model]
              matched_columns = model_class.columns.select { |column| column.name =~ column_regexp || column.comment =~ column_regexp }
              next if matched_columns.empty?
              matched_columns.each do |column|
                pk = if [connection.primary_key(definition[:table])].flatten.include?(column.name)
                       'Y'
                     else
                       ''
                     end
                t << [pk, definition[:table], model_class.name, column.name, column.sql_type,
                      column.sql_type_metadata.type, column.sql_type_metadata.limit || '',
                      column.sql_type_metadata.precision || '', column.sql_type_metadata.scale || '', column.default || '',
                      column.null, "#{definition[:comment]} - #{column.comment}"]
              end
            end
          end
          puts table
        end
      end
    end
  end

  Pry.commands.block_command 'm' do |arg|
    puts
    if arg.start_with?('c=') or arg.start_with?('column=')
      column_regexp = arg.sub(/^c(olumn)?=/, '')
      Models::models_table(nil, column_regexp.try { |e| e.start_with?('/') ? eval(e) : Regexp.new(e) })
    else
      puts Models::models_table(arg.try { |e| e.start_with?('/') ? eval(e) : Regexp.new(e) }, nil)
    end
  end

  Pry.commands.alias_command 'l', 'm'
end

module Kernel
  def models
    Arql::Commands::Models::models
  end

  def tables
    models
  end

  def model_classes
    ::ArqlModel.subclasses
  end

  def table_names
    models[2..-1].map(&:first)
  end

  def model_names
    models[2..-1].map(&:second)
  end
end
