Ransack::Search.class_eval do
  def t(*attrs, **options)
    result.t(*attrs, **options)
  end

  def vd(*attrs, **options)
    result.vd(*attrs, **options)
  end

  def v
    result.v
  end

  def a
    result.a
  end

  def write_csv(filename, *fields, **options)
    result.write_csv(filename, *fields, **options)
  end

  def write_excel(filename, *fields, **options)
    result.write_excel(filename, *fields, **options)
  end

  def dump(filename, batch_size=500)
    result.dump(filename, batch_size)
  end
end