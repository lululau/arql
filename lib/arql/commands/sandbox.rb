module Arql::Commands
  module Sandbox
    class << self
      attr_accessor :enabled

      @sandbox_callback = proc do
        begin_transaction(joinable: false)
      end

      def enter
        ActiveRecord::ConnectionAdapters::AbstractAdapter.set_callback(:checkout, :after, &@sandbox_callback)
        ActiveRecord::Base.connection.begin_transaction(joinable: false)
        @enabled = true
      end

      def quit
        ActiveRecord::ConnectionAdapters::AbstractAdapter.skip_callback(:checkout, :after, &@sandbox_callback)
        @enabled = false

        puts "begin_transaction callbacks removed."
        puts "You still have open %d transactions open, don't forget commit or rollback them." % ActiveRecord::Base.connection.open_transactions if ActiveRecord::Base.connection.open_transactions > 0
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
