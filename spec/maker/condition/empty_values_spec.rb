require_relative '../../spec_helper'
require 'sql/maker/condition'

describe SQL::Maker::Condition do
  it '[]' do
    w = SQL::Maker::Condition.new()
    w.add(:x => [])
    expect(w.as_sql).to be == '(0=1)'
    expect(w.bind.join(', ')).to be == ''
  end

  it 'in' do
    w = SQL::Maker::Condition.new()
    w.add(:x => { 'IN' => [] })
    expect(w.as_sql).to be == '(0=1)'
    expect(w.bind.join(', ')).to be == ''
  end

  it 'not in' do
    w2 = SQL::Maker::Condition.new()
    w2.add(:x => { 'NOT IN' => [] })
    expect(w2.as_sql).to be == '(1=1)'
    expect(w2.bind.join(', ')).to be == ''
  end
end
