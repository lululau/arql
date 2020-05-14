module Arql::Commands
  module Redefine
    class << self
      def redefine
        Arql::Definition.redefine
      end
    end

    Pry.commands.block_command 'redefine' do
      Redefine.redefine
    end

    Pry.commands.alias_command 'redef', 'redefine'
  end
end
