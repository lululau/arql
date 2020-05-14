module Arql::Commands
  module Reconnect
    class << self
      def reconnect
        ActiveRecord::Base.connection.reconnect!
      end
    end

    Pry.commands.block_command 'reconnect' do
      Reconnect.reconnect
    end
  end
end
