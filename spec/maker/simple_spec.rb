require_relative '../spec_helper'
require 'sql/maker'

describe 'select_query' do
  include SQL::Maker::Helper

  context 'driver: sqlite' do
    builder = SQL::Maker.new(:driver => 'sqlite')

    it do
      stmt = builder.select_query('foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => sql_raw('yo')})
      expect(stmt.as_sql).to be == %Q{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)\nORDER BY yo}
      expect(stmt.bind.join(',')).to be == 'baz,man'
    end
  end

  context 'driver: mysql, quote_char: "", new_line: " "' do
    builder = SQL::Maker.new(:driver => 'mysql', :quote_char => '', :new_line => ' ')

    it do
      stmt = builder.select_query('foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => 'yo'})
      expect(stmt.as_sql).to be == %Q{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?) ORDER BY yo}
      expect(stmt.bind.join(',')).to be == 'baz,man'
    end
  end

  it 'new_condition' do
    builder = SQL::Maker.new(:driver => 'sqlite', :quote_char => %q{`}, :name_sep => %q{.})
    cond = builder.new_condition
    expect(cond.is_a?(SQL::Maker::Condition)).to be_truthy
    expect(cond.quote_char).to be == %q{`}
    expect(cond.name_sep).to be == %q{.}
  end

  context 'new_select' do
    it 'driver: sqlite, quote_char: "`", name_sep: "."' do
      builder = SQL::Maker.new(:driver => 'sqlite', :quote_char => %q{`}, :name_sep => %q{.})
      select = builder.new_select()
      expect(select.is_a?(SQL::Maker::Select)).to be_truthy
      expect(select.quote_char).to be == %q{`}
      expect(select.name_sep).to be == %q{.}
      expect(select.new_line).to be == %Q{\n}
    end

    it 'driver: mysql, quote_char: "", new_line: " "' do
      builder = SQL::Maker.new(:driver => 'sqlite', :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ })
      select = builder.new_select()
      expect(select.is_a?(SQL::Maker::Select)).to be_truthy
      expect(select.quote_char).to be == %q{}
      expect(select.name_sep).to be == %q{.}
      expect(select.new_line).to be == %q{ }
    end
  end
end
