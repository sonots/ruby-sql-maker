require_relative '../../spec_helper'
require 'sql/maker/condition'

describe 'SQL::Maker::Condition' do
  let(:w1) do
    w1 = SQL::Maker::Condition.new()
    w1.add(:x => 1)
    w1.add(:y => 2)
  end
  let(:w2) { SQL::Maker::Condition.new() }
  let(:w3) { SQL::Maker::Condition.new() }

  it 'and_before' do
    w = (w1 & w2)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?))'
    expect(w.bind.join(', ')).to be == '1, 2'

    w.add(:z => 99)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?)) AND (z = ?)'
    expect(w.bind.join(', ')).to be == '1, 2, 99'
  end

  it 'and_after' do 
    w = (w2 & w1)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?))'
    expect(w.bind.join(', ')).to be == '1, 2'

    w.add(:z => 99)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?)) AND (z = ?)'
    expect(w.bind.join(', ')).to be == '1, 2, 99'
  end

  it 'or_before' do
    w = (w1 | w2)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?))'
    expect(w.bind.join(', ')).to be == '1, 2'

    w.add(:z => 99)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?)) AND (z = ?)'
    expect(w.bind.join(', ')).to be == '1, 2, 99'
  end

  it 'or_after' do
    w = (w2 | w1)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?))'
    expect(w.bind.join(', ')).to be == '1, 2'

    w.add(:z => 99)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?)) AND (z = ?)'
    expect(w.bind.join(', ')).to be == '1, 2, 99'
  end

  it 'and_both' do
    w = (w2 & w3)
    expect(w.as_sql).to be == ''
    expect(w.bind.join(', ')).to be == ''

    w.add(:z => 99)
    expect(w.as_sql).to be == '(z = ?)'
    expect(w.bind.join(', ')).to be == '99'
  end

  it 'or_both' do
    w = (w2 | w3)
    expect(w.as_sql).to be == ''
    expect(w.bind.join(', ')).to be == ''

    w.add(:z => 99)
    expect(w.as_sql).to be == '(z = ?)'
    expect(w.bind.join(', ')).to be == '99'
  end
end
