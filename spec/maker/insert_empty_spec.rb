require_relative '../spec_helper'
require 'sql/maker'

describe 'SQL::Maker#insert' do
  def normalize(sql)
    sql.gsub(/\n/, ' ')
  end

  # see https://github.com/tokuhirom/SQL-Maker/issues/11
  it 'sqlite' do
    maker = SQL::Maker.new(:driver => 'SQLite')
    sql, bind = maker.insert('foo', {})
    expect(normalize(sql)).to be == 'INSERT INTO "foo" DEFAULT VALUES'
    expect(bind.size).to be == 0
  end

  it 'mysql' do
    maker = SQL::Maker.new(:driver => 'mysql')
    sql, bind = maker.insert('foo', {})
    expect(normalize(sql)).to be == 'INSERT INTO `foo` () VALUES ()'
    expect(bind.size).to be == 0
  end
end
