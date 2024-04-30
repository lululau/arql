module Ransack
  module Adapters
    module ActiveRecord
      module Base
        def ransack(params = {}, options = {})
          old_base_connection = ::ActiveRecord::Base.method(:connection)
          connection_obj = connection
          ::ActiveRecord::Base.define_singleton_method(:connection) { connection_obj }
          Search.new(self, params, options)
        ensure
          ::ActiveRecord::Base.define_singleton_method(:connection, old_base_connection)
        end
      end
    end
  end

  class Search
    def result(opts = {})
      old_base_connection = ::ActiveRecord::Base.method(:connection)
      connection_obj = @context.klass.connection
      ::ActiveRecord::Base.define_singleton_method(:connection) { connection_obj }
      @context.evaluate(self, opts)
    ensure
      ::ActiveRecord::Base.define_singleton_method(:connection, old_base_connection)
    end
  end
end