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

  def parse_excel
    if File.file?(File.expand_path(self))
      Kernel.parse_excel(File.expand_path(self))
    else
      raise "File not found: #{self}"
    end
  end

  def parse_csv
    if File.file?(File.expand_path(self))
      Kernel.parse_csv(File.expand_path(self))
    else
      raise "File not found: #{self}"
    end
  end

  def parse_json
    if File.file?(File.expand_path(self))
      Kernel.parse_json(File.expand_path(self))
    else
      raise "File not found: #{self}"
    end
  end

  def parse
    if File.file?(File.expand_path(self))
      if self =~ /\.xlsx?$/i
        parse_excel
      elsif self =~ /\.csv$/i
        parse_csv
      elsif self =~ /\.json$/i
        parse_json
      else
        raise "File type not supported: #{self}"
      end
    else
      raise "File not found: #{self}"
    end
  end

  def vd
    if File.file?(File.expand_path(self))
      system "vd '#{File.expand_path(self)}'"
      print "\033[5 q"
    else
      raise "File not found: #{self}"
    end
  end
end
