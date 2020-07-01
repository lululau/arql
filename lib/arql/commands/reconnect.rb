module Arql::Commands
  module Reconnect
    class << self
      def reconnect
        Arql::SSHProxy.reconnect if Arql::App.config[:ssh].present?
        ActiveRecord::Base.connection.reconnect! unless ActiveRecord::Base.connection.active?
      end

      def reconnect!
        Arql::SSHProxy.reconnect! if Arql::App.config[:ssh].present?
        ActiveRecord::Base.connection.reconnect!
      end
    end

    Pry.commands.block_command 'reconnect' do
      Reconnect.reconnect
    end

    Pry.commands.block_command 'reconnect!' do
      Reconnect.reconnect!
    end
  end
end
