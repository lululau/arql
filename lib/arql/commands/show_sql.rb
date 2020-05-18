module Arql::Commands
  module ShowSql
    class << self
      def show
        return if Arql::App.log_io.is_a?(Arql::MultiIO) && Arql::App.log_io.include?(STDOUT)
        Arql::App.log_io ||= Arql::MultiIO.new
        ActiveRecord::Base.logger = Logger.new(Arql::App.log_io)
        Arql::App.log_io << STDOUT
      end

      def hide
        return if !Arql::App.log_io.is_a?(Arql::MultiIO) || !Arql::App.log_io.include?(STDOUT)
        Arql::App.log_io.delete(STDOUT)
      end
    end

    Pry.commands.block_command 'show-sql' do
      ShowSql.show
    end

    Pry.commands.block_command 'hide-sql' do
      ShowSql.hide
    end
  end
end
