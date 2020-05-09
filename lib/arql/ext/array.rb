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
end
