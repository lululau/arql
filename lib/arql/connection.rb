module Arql
  class Connection
    class << self
      def open(options)
        ActiveRecord::Base.establish_connection(options)
        $C = ActiveRecord::Base.connection
      end
    end
  end
end
