module Kernel
  def sql(sql)
    ActiveRecord::Base.connection.exec_query(sql)
  end
end
