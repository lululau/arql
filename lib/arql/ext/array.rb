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
    raise 'Empty array' unless present?
    raise 'All elements must be instances of the same ActiveRecord model class' unless map(&:class).uniq.size == 1 && first.is_a?(ActiveRecord::Base)
    t = []
    t << first.attribute_names
    t << nil
    each do |e|
      t << e.attributes.values_at(*first.attribute_names).map(&:as_json)
    end
    t
  end
end
