require_relative '../spec_helper'
require 'sql/query_maker'
require 'sql/maker/helper'

def test(src, expected_term, expected_bind)
  describe 'SQL::QueryMaker' do
    include SQL::Maker::Helper

    it src do
      term = instance_eval src
      sql = term.as_sql
      bind = term.bind
      expect(sql).to be == expected_term
      expect(bind).to be == expected_bind
    end
  end
end

begin
  file = File.open("#{ROOT}/lib/sql/query_maker.rb")
  while line = file.gets
    break if line =~ /=head1 CHEAT SHEET/
  end
  while line = file.gets
    src = $1 if line =~ /IN:\s*(.+)\s*$/
    query = eval($1, binding) if line =~ /OUT QUERY:(.+)/
    if line =~ /OUT BIND:(.+)/
      bind = eval($1, binding)
      test(src, query, bind)
    end
  end
end
