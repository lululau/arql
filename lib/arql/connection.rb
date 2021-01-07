module Arql
  class Connection
    class << self
      def open(options)
        ActiveRecord::Base.establish_connection(options)
        $C = ActiveRecord::Base.connection
        $C.define_singleton_method(:dump) do |filename, no_create_db=false|
          Arql::Mysqldump.new.dump_database(filename, no_create_db)
        end
      end
    end
  end
end
