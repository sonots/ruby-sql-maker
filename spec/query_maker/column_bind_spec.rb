require_relative '../spec_helper'
require 'sql/query_maker'
require 'sql/maker/helper'

describe 'SQL::QueryMaker' do
  include SQL::Maker::Helper

  it "sql_in" do
    expect(sql_in(['bar','baz']).as_sql('foo')).to be == '`foo` IN (?,?)'
  end

  it "sql_lt" do
    expect(sql_lt(3).as_sql('foo')).to be == '`foo` < ?'
  end

  it "sql_not_in" do
    expect(sql_not_in(['bar','baz']).as_sql('foo')).to be == '`foo` NOT IN (?,?)'
  end

  it "sql_ne" do
    expect(sql_ne('bar').as_sql('foo')).to be == '`foo` != ?'
  end

  it "sql_is_not_null" do
    expect(sql_is_not_null().as_sql('foo')).to be == '`foo` IS NOT NULL'
  end

  it "sql_between" do
    expect(sql_between('1', '2').as_sql('foo')).to be == '`foo` BETWEEN ? AND ?'
  end

  it "sql_like" do
    expect(sql_like('xaic').as_sql('foo')).to be == '`foo` LIKE ?'
  end

  it "sql_or" do
    expect(sql_or([sql_gt('bar'), sql_lt('baz')]).as_sql('foo')).to be == '(`foo` > ?) OR (`foo` < ?)'
  end

  it "sql_and" do
    expect(sql_and([sql_gt('bar'), sql_lt('baz')]).as_sql('foo')).to be == '(`foo` > ?) AND (`foo` < ?)'
  end
  
  it "sql_op" do
    expect(sql_op('IN (SELECT foo_id FROM bar WHERE t=?)',[44]).as_sql('foo_id')).to be == '`foo_id` IN (SELECT foo_id FROM bar WHERE t=?)'
  end

  it "sql_in([])" do
    expect(sql_in([]).as_sql('foo')).to be == '0=1'
  end

  it "sql_not_in([])" do
    expect(sql_not_in([]).as_sql('foo')).to be == '1=1'
  end
end
