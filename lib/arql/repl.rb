require 'pry'
require 'pry-byebug'
require 'arql/commands'
require 'rainbow'

module Arql
  class Repl
    def initialize
      Pry.config.prompt = Pry::Prompt.new("", "", prompt)
      main_object.pry
    end

    def main_object
      return @main if @main
      @main = Object.new
      @main.instance_eval do
        def inspect
          to_s
        end
        def to_s
          "main"
        end
      end
      @main
    end

    def prompt
      [proc do |obj, nest_level, _|
         if obj == main_object && nest_level == 0
           nest_level_prompt = ''
         else
           nest_level_prompt = "(#{obj}:#{nest_level})"
         end
         "%s#{nest_level_prompt} %s " % [Rainbow('ARQL').red, Rainbow('❯').green]
       end]
    end
  end
end
