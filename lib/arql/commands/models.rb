module Arql::Commands
  module Models
    class << self
      def models
        "\nTables:\n" + Arql::Definition.models.map do |definition|
          "    %s" % definition[:table]
        end.join("\n")
      end

    end

    Pry.commands.block_command 'models' do
      puts Models::models
    end

    Pry.commands.alias_command 'm', 'models'
    Pry.commands.alias_command 'l', 'models'
    Pry.commands.alias_command 'tables', 'models'
  end
end
