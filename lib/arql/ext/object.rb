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
end
