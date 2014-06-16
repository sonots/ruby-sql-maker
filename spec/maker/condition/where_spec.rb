require_relative '../../spec_helper'
require 'sql/maker/condition'

describe SQL::Maker::Condition do
  let(:w1) do
    w1 = SQL::Maker::Condition.new()
    w1.add(:x => 1)
    w1.add(:y => 2)
  end
  let(:w2) do
    w2 = SQL::Maker::Condition.new()
    w2.add(:a => 3)
    w2.add(:b => 4)
  end

  it 'and' do
    w = (w1 & w2)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?)) AND ((a = ?) AND (b = ?))'
    expect(w.bind.join(', ')).to be == '1, 2, 3, 4'

    w.add(:z => 99)
    expect(w.as_sql).to be == '((x = ?) AND (y = ?)) AND ((a = ?) AND (b = ?)) AND (z = ?)'
    expect(w.bind.join(', ')).to be == '1, 2, 3, 4, 99'
  end

  it 'or' do
    w = (w1 | w2)
    expect(w.as_sql).to be == '(((x = ?) AND (y = ?)) OR ((a = ?) AND (b = ?)))'
    expect(w.bind.join(', ')).to be == '1, 2, 3, 4'

    w.add(:z => 99)
    expect(w.as_sql).to be == '(((x = ?) AND (y = ?)) OR ((a = ?) AND (b = ?))) AND (z = ?)'
    expect(w.bind.join(', ')).to be == '1, 2, 3, 4, 99'
  end
end
