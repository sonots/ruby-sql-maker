require_relative '../../spec_helper'
require 'sql/maker/condition'

describe 'SQL::Maker::Condition' do
  it 'with values' do
    w1 = SQL::Maker::Condition.new()
    w1.add_raw( 'a = ?' => 1 )
    w1.add_raw( 'b = ?' => 2 )

    expect(w1.as_sql).to be == '(a = ?) AND (b = ?)'
    expect(w1.bind.join(',')).to be == '1,2'

    w2 = SQL::Maker::Condition.new()
    w2.add_raw( 'b = IF(c > 0, ?, ?)' => [0, 1] )
    w2.add_raw( 'd = ?' => [2]) 

    expect(w2.as_sql).to be == '(b = IF(c > 0, ?, ?)) AND (d = ?)'
    expect(w2.bind.join(',')).to be == '0,1,2'
  end

  it 'without values' do
    w = SQL::Maker::Condition.new()
    w.add_raw( 'a IS NOT NULL' )
    w.add_raw( 'b IS NULL' )

    expect(w.as_sql).to be == '(a IS NOT NULL) AND (b IS NULL)'
    expect(w.bind.join(',')).to be == ''
  end
end
