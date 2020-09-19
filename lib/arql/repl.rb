require 'pry'
require 'pry-byebug'
require 'arql/commands'
require 'rainbow'

module Arql
  class Repl
    def initialize
      Pry.config.prompt = Pry::Prompt.new("", "", prompt)
      Pry.start
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
      [proc do |obj, nest_level, pry_instance|
         if obj == main_object && nest_level == 0
           nest_level_prompt = ''
         else
           nest_level_prompt = if nest_level.zero?
                                 "(#{obj})"
                               else
                                 "(#{obj}:#{nest_level})"
                               end
         end
         "%s#{Rainbow('@').green}%s#{nest_level_prompt} [%d] %s " % [Rainbow('ARQL').red, Rainbow(App.prompt).yellow, pry_instance.input_ring.count, Rainbow('❯').green]
       end]
    end
  end
end
