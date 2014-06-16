require_relative '../spec_helper'
require 'sql/query_maker'
require 'sql/maker/helper'

describe 'SQL::QueryMaker' do
  include SQL::Maker::Helper

  it 'orderd_hash' do
    q = sql_and(foo: 1, bar: sql_eq(2), baz: sql_lt(3))
    expect(q.as_sql).to be == '(`foo` = ?) AND (`bar` = ?) AND (`baz` < ?)'
    expect(q.bind).to be == [1,2,3]
  end
end
