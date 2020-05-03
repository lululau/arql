module Arql
  class MultiIO
    def initialize(*targets)
      @targets = targets
    end

    def write(*args)
      @targets.each {|t| t.write(*args)}
    end

    def close
      @targets.each(&:close)
    end

    def <<(target)
      @targets ||= []
      @targets << target
    end
  end
end
