require 'terminal-table'

module Arql::Commands
  module Models
    class << self
      def models
        Terminal::Table.new do |t|
          t << ['Table Name', 'Model Class', 'Abbr']
          t << :separator
          Arql::Definition.models.each do |definition|
            t << [definition[:table], definition[:model].name, definition[:abbr] || '']
          end
        end
      end

    end

    Pry.commands.block_command 'models' do
      puts
      puts Models::models
    end

    Pry.commands.alias_command 'm', 'models'
    Pry.commands.alias_command 'l', 'models'
    Pry.commands.alias_command 'tables', 'models'
  end
end
