require_relative '../spec_helper'
require 'sql/query_maker'
require 'sql/maker/helper'

describe 'SQL::QueryMaker' do
  include SQL::Maker::Helper

  it "sql_eq" do
    expect { sql_eq('foo' => [1,2,3]) }.to raise_error
  end

  it "sql_in" do
    expect { sql_eq('foo' => [[1,2,3], 4]) }.to raise_error
  end

  it "sql_and" do
    expect { sql_eq('foo' => [[1,2], 3]) }.to raise_error
  end
end
