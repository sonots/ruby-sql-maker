require_relative '../../../spec_helper'
require 'sql/maker/select/oracle'

describe 'SQL::Maker::Select::Oracle' do
  let(:sel) do
    SQL::Maker::Select::Oracle.new( :new_line => %q{ } )
      .add_select('foo')
      .add_from('user')
      .limit(10)
      .offset(20)
  end

  it do
    expect(sel.as_sql).to be == 'SELECT * FROM ( SELECT foo, ROW_NUMBER() OVER (ORDER BY 1) R FROM user LIMIT 10 OFFSET 20 ) WHERE  R BETWEEN 20 + 1 AND 10 + 20'
  end
end
