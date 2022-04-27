module Arql
  class MultiIO
    def initialize(*targets)
      @targets = targets
    end

    def write(*args)
      @targets.each do |t|
        if t.isatty
          t.write(*args)
        else
          t.write(*(args.map { |str| str.gsub(/\e\[(\d+)m/, '')}))
        end
        t.flush
      end
    end

    def close
      @targets.each(&:close)
    end

    def <<(target)
      @targets ||= []
      @targets << target
    end

    def delete(io)
      @targets.delete(io)
    end

    def include?(io)
      @targets.include?(io)
    end
  end
end
