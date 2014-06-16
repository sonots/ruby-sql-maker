require_relative '../spec_helper'
require 'sql/maker'

describe 'SQL::Maker' do
  context 'driver: sqlite'do
    builder = SQL::Maker.new(:driver => 'sqlite')

    it 'none' do
      sql, bind = builder.where( {} )
      expect(sql).to be == %Q{}
      expect(bind.join(',')).to be == ''
    end

    it 'simple' do
      sql, bind = builder.where( {:x => 3} )
      expect(sql).to be == %Q{("x" = ?)}
      expect(bind.join(',')).to be == '3'
    end

    it 'array' do
      # i probably don't need to support this
      sql, bind = builder.where( [:x, 3] )
      expect(sql).to be == %Q{("x" = ?)}
      expect(bind.join(',')).to be == '3'
    end
  end
end

