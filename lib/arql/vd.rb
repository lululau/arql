require 'csv'

module Arql
  class VD
    COMMAND = 'vd'

    attr_accessor :rows

    def initialize
      return unless check_command_installation
      @rows = []
      yield self
      command = "#{COMMAND} -f csv"
      IO.popen(command, 'w+') do |io|
        io.puts(csv)
        io.close_write
      end
      print "\033[5 q"
    end

    def <<(row)
      rows << row
    end

    def csv
      CSV.generate do |csv|
        rows.each do |row|
          csv << row
        end
      end
    end

    def check_command_installation
      `which #{COMMAND}`
      if $?.exitstatus != 0
        puts "Please install vd (visidata) command, see: https://www.visidata.org/"
      else
        true
      end
    end
  end
end
