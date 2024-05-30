ENV['RAILS_DISABLE_DEPRECATED_TO_S_CONVERSION'] = 'true'
require 'table_print'
require 'roo'
require 'caxlsx'
require 'csv'
require 'net/ssh/gateway'
require 'arql/version'
require 'arql/id'
require 'arql/multi_io'
require 'arql/ext'
require 'arql/repl'
require 'arql/ssh_proxy'
require 'arql/app'
require 'arql/cli'
require 'arql/mysqldump'
require 'arql/vd'
require 'active_support/all'
require 'active_record'
require 'kaminari/activerecord'
require 'composite_primary_keys'
require 'ransack'

require 'arql/ext/active_record/base'
require 'arql/ext/active_record/relation'
require 'arql/ext/active_record/result'
require 'arql/ext/ransack/search'

$iruby = false

module Arql
  def self.create(options)
    if ::Object.const_defined?(:IRuby) && ::IRuby.const_defined?(:OStream) && $stdout.is_a?(IRuby::OStream)
      IRuby::Kernel.instance.switch_backend!(:pry)
      $iruby = true
    end
    App.create(options)
  end
end

if ::Object.const_defined?(:IRuby)
  require 'arql/chart'
  ::Kernel.include(Arql::Chart)
end