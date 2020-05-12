require 'terminal-table'

module Arql::Commands
  module Models
    class << self
      def models
        t = []
        t << ['Table Name', 'Model Class', 'Abbr']
        t << nil
        Arql::Definition.models.each do |definition|
          t << [definition[:table], definition[:model].name, definition[:abbr] || '']
        end
        t
      end

      def models_table
        Terminal::Table.new do |t|
          models.each { |row| t << (row || :separator) }
        end
      end
    end
  end

  Pry.commands.block_command 'm' do
    puts
    puts Models::models_table
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
