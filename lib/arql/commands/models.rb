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

      def models_table(regexp)
        Terminal::Table.new do |t|
          models.each_with_index { |row, idx| t << (row || :separator) if row.nil? ||
            regexp.nil? ||
            idx.zero? ||
            row.any? { |e| e =~ regexp }
          }
        end
      end
    end
  end

  Pry.commands.block_command 'm' do |regexp|
    puts
    puts Models::models_table(regexp.try { |e| eval(e) })
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
end
