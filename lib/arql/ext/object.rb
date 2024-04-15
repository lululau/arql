class Object

  def j
    to_json
  end

  def jj
    JSON.pretty_generate(JSON.parse(to_json))
  end

  def jp
    puts j
  end

  def jjp
    puts jj
  end

  def a
    [self]
  end

  class << self
    def const_missing(name)
      return super unless const_defined?(:Arql)
      return super unless Arql.const_defined?(:App)
      return super unless Arql::App.instance&.definitions&.present?

      Arql::App.instance.definitions.lazy.filter do |_, definition|
        definition.namespace_module.const_defined?(name)
      end.map do |_, definition|
          definition.namespace_module.const_get(name)
      end.first || super
    end
  end
end
