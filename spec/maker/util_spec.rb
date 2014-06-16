require_relative '../spec_helper'
require 'sql/maker/util'

describe 'SQL::Maker::Util' do
  it { expect(SQL::Maker::Util.quote_identifier('foo.*', '`', '.')).to be == '`foo`.*' }
end
