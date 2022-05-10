module Arql
  class Connection
    class << self
      def open(options)
        print "Establishing DB connection to #{options[:host]}:#{options[:port]}"
        ActiveRecord::Base.establish_connection(options)
        print "\u001b[2K"
        puts "\rDB connection to #{options[:host]}:#{options[:port]} established\n"
        $C = ActiveRecord::Base.connection
        $C.define_singleton_method(:dump) do |filename, no_create_db=false|
          Arql::Mysqldump.new.dump_database(filename, no_create_db)
        end
      end
    end
  end
end
