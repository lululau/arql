ActiveRecord::Result.class_eval do
  def t(*attrs, **options)
    to_a.t(*attrs, **options)
  end

  def vd(*attrs, **options)
    to_a.vd(*attrs, **options)
  end

  def v
    to_a.v
  end

  def a
    to_a
  end

  def write_csv(filename, *fields, **options)
    to_a.write_csv(filename, *fields, **options)
  end

  def write_excel(filename, *fields, **options)
    to_a.write_excel(filename, *fields, **options)
  end

  def dump(filename, batch_size=500)
    to_a.dump(filename, batch_size)
  end
end