class Object

  def j
    puts to_json
  end

  def jj
    puts JSON.pretty_generate(JSON.parse(to_json))
  end
end
