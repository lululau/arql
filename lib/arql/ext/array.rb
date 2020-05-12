class Array
  def to_insert_sql(batch_size=500)
    raise 'All element should be an ActiveRecord instance object' unless all? { |e| e.is_a?(ActiveRecord::Base) }
    group_by(&:class).map do |(klass, records)|
      klass.to_insert_sql(records, batch_size)
    end.join("\n")
  end

  def to_upsert_sql(batch_size=500)
    raise 'All element should be an ActiveRecord instance object' unless all? { |e| e.is_a?(ActiveRecord::Base) }
    group_by(&:class).map do |(klass, records)|
      klass.to_upsert_sql(records, batch_size)
    end.join("\n")
  end

  def v
    return self unless present?
    t = []
    if map(&:class).uniq.size == 1
      if first.is_a?(ActiveRecord::Base)
        t << first.attribute_names
        t << nil
        each do |e|
          t << e.attributes.values_at(*first.attribute_names).map(&:as_json)
        end
      elsif first.is_a?(Array)
        t = map { |a| a.map(&:as_json) }
      elsif first.is_a?(Hash) || first.is_a?(ActiveSupport::HashWithIndifferentAccess)
        t << first.keys
        t << nil
        each do |e|
          t << e.values_at(*first.keys).map(&:as_json)
        end
      else
        return self
      end
    end
    t
  end
end
