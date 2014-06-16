require 'sql/query_maker'
require 'sql/maker/select_set'

module SQL::Maker::Helper
  # SQL::QueryMaker Helper
  (%w[and or in not_in op raw] + SQL::QueryMaker::FNOP.keys).each do |fn|
    method = "sql_#{fn}" # sql_and
    define_method(method) do |*args|
      SQL::QueryMaker.send(method, *args)
    end
    module_function method
  end

  # SQL::Maker::SelectSet Helper
  SQL::Maker::SelectSet::FNOP.each do |fn|
    method = "sql_#{fn}" # sql_union
    define_method(method) do |*args|
      SQL::Maker::SelectSet.send(method, *args)
    end
    module_function method
  end
end
