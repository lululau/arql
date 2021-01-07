class String
  def p
    puts self
  end

  def expa
    File.expand_path(self)
  end

  def f
    expa
  end
end
