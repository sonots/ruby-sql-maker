require_relative '../../spec_helper'
require 'sql/maker/condition'
require 'sql/maker/helper'

include SQL::Maker::Helper

def test(input, expected_term, expected_bind)
  describe 'SQL::Maker::Condition' do
    it input do
      source = eval(input, binding)
      cond = SQL::Maker::Condition.new(
        :quote_char => '`',
        :name_sep   => '.',
      )
      cond.add(source)
      sql = cond.as_sql
      sql = sql.gsub(/^\(/, '').gsub(/\)$/, '')
      expect(sql).to be == expected_term
      expect(cond.bind).to be == expected_bind
    end
  end
end

begin
  file = File.open("#{ROOT}/doc/sql/maker/condition.md")
  while line = file.gets
    break if line =~ /CONDITION CHEAT SHEET/
  end
  while line = file.gets
    next if line =~ /^ *#/
    src = $1 if line =~ /IN:\s*(.+)\s*$/
    query = eval($1, binding) if line =~ /OUT QUERY:(.+)/
    if line =~ /OUT BIND:(.+)/
      bind = eval($1, binding)
      test(src, query, bind)
    end
  end
end
