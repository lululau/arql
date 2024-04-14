module Arql::Commands
  module Reconnect
    class << self
      def reconnect
        Arql::App.instance.definitions.each do |_, definition|
          definition.ssh_proxy.reconnect if definition.options[:ssh].present?
          definition.connection.reconnect! unless definition.connection.active?
        end
      end

      def reconnect!
        Arql::App.instance.definitions.each do |_, definition|
          definition.ssh_proxy.reconnect if definition.options[:ssh].present?
          definition.connection.reconnect!
        end
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
