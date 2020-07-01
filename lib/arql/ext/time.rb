require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/object/json'

class Time
  DATE_FORMATS ||= {}
  DATE_FORMATS[:default] = '%Y-%m-%d %H:%M:%S'

  def inspect
    to_s
  end

  def as_json(*args)
    to_s
  end
end
