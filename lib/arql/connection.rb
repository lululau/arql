require 'active_record'

module Arql
  class Connection
    class << self
      def open(options)
        ActiveRecord::Base.establish_connection(options)
      end
    end
  end
end
