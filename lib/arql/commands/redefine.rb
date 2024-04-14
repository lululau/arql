module Arql::Commands
  module Redefine
    class << self
      def redefine
        Arql::App.instance.definitions.each do |_, definition|
          definition.redefine
        end
      end
    end

    Pry.commands.block_command 'redefine' do
      Redefine.redefine
    end

    Pry.commands.alias_command 'redef', 'redefine'
  end
end
