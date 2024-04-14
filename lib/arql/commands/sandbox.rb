module Arql::Commands
  module Sandbox
    class << self
      attr_accessor :enabled

      @sandbox_callback = proc do
        begin_transaction(joinable: false)
      end

      def enter
        ActiveRecord::ConnectionAdapters::AbstractAdapter.set_callback(:checkout, :after, &@sandbox_callback)
        Arql::App.instance.definitions.each do |_, definition|
          definition.connection.begin_transaction(joinable: false)
        end
        @enabled = true
      end

      def quit
        ActiveRecord::ConnectionAdapters::AbstractAdapter.skip_callback(:checkout, :after, &@sandbox_callback)
        Arql::App.instance.definitions.each do |_, definition|
          definition.connection.rollback_transaction
        end
        @enabled = false
      end
    end

    Pry.commands.block_command 'sandbox-enter' do
      Sandbox.enter
    end

    Pry.commands.block_command 'sandbox-quit' do
      Sandbox.quit
    end
  end
end
