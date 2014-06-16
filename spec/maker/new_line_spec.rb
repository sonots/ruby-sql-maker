require_relative '../spec_helper'
require 'sql/maker'

describe 'SQL::Maker' do
  it 'empty string' do
    builder = SQL::Maker.new(:new_line => '', :driver => 'mysql')
    expect(builder.new_line).to be == ''
  end
end
