ActiveRecord::Relation.class_eval do
  def t(*attrs, **options)
    records.t(*attrs, **options)
  end

  def vd(*attrs, **options)
    records.vd(*attrs, **options)
  end

  def v
    records.v
  end

  def a
    to_a
  end

  def write_csv(filename, *fields, **options)
    records.write_csv(filename, *fields, **options)
  end

  def write_excel(filename, *fields, **options)
    records.write_excel(filename, *fields, **options)
  end

  def dump(filename, batch_size=500)
    records.dump(filename, batch_size)
  end
end