require_relative '../spec_helper'
require 'sql/maker'
require 'sql/maker/helper'

describe 'SQL::Maker#insert' do
  include SQL::Maker::Helper

  context 'driver sqlite' do
    it 'hash column-value' do
      builder = SQL::Maker.new(:driver => 'sqlite')
      sql, bind = builder.insert('foo', {:bar => 'baz', :john => 'man', :created_on => ["datetime('now')"], :updated_on => ["datetime(?)", "now"]})
      expect(sql).to be == %Q{INSERT INTO "foo"\n("bar", "john", "created_on", "updated_on")\nVALUES (?, ?, datetime('now'), datetime(?))}
      expect(bind.join(',')).to be == 'baz,man,now'
    end

    # it 'array column-value' do

    it 'insert ignore, hash column-value' do
      builder = SQL::Maker.new(:driver => 'sqlite')
      sql, bind = builder.insert('foo', { :bar => 'baz', :john => 'man', :created_on => ["datetime('now')"], :updated_on => ["datetime(?)", "now"]}, { :prefix => 'INSERT IGNORE' })
      expect(sql).to be == %Q{INSERT IGNORE "foo"\n("bar", "john", "created_on", "updated_on")\nVALUES (?, ?, datetime('now'), datetime(?))}
      expect(bind.join(',')).to be == 'baz,man,now'
    end

    # it 'insert ignore, array column-value' do

    it 'term' do
      builder = SQL::Maker.new(:driver => 'sqlite')
      sql, bind = builder.insert('foo', {:bar => 'baz', :john => 'man', :created_on => sql_raw("datetime('now')"), :updated_on => sql_raw("datetime(?)", "now")})
      expect(sql).to be == %Q{INSERT INTO "foo"\n("bar", "john", "created_on", "updated_on")\nVALUES (?, ?, datetime('now'), datetime(?))}
      expect(bind.join(',')).to be == 'baz,man,now'
    end
  end

  context 'driver mysql' do
    it 'hash column-value' do
      builder = SQL::Maker.new(:driver => 'mysql')
      sql, bind = builder.insert('foo', {:bar => 'baz', :john => 'man', :created_on => ["NOW()"], :updated_on => ["FROM_UNIXTIME(?)", 1302536204 ] })
      expect(sql).to be == %Q{INSERT INTO `foo`\n(`bar`, `john`, `created_on`, `updated_on`)\nVALUES (?, ?, NOW(), FROM_UNIXTIME(?))}
      expect(bind.join(',')).to be == 'baz,man,1302536204'
    end

    # it 'array column-value' do
    
    it 'insert ignore, hash column-value' do
      builder = SQL::Maker.new(:driver => 'mysql')
      sql, bind = builder.insert('foo', { :bar => 'baz', :john => 'man', :created_on => ["NOW()"], :updated_on => ["FROM_UNIXTIME(?)", 1302536204 ] }, { :prefix => 'INSERT IGNORE' })
      expect(sql).to be == %Q{INSERT IGNORE `foo`\n(`bar`, `john`, `created_on`, `updated_on`)\nVALUES (?, ?, NOW(), FROM_UNIXTIME(?))}
      expect(bind.join(',')).to be == 'baz,man,1302536204'
    end

    # it 'insert ignore, array column-value' do
    
    it 'term' do
      builder = SQL::Maker.new(:driver => 'mysql')
      sql, bind = builder.insert('foo', {:bar => 'baz', :john => 'man', :created_on => sql_raw("NOW()"), :updated_on => sql_raw("FROM_UNIXTIME(?)", 1302536204)})
      expect(sql).to be == %Q{INSERT INTO `foo`\n(`bar`, `john`, `created_on`, `updated_on`)\nVALUES (?, ?, NOW(), FROM_UNIXTIME(?))}
      expect(bind.join(',')).to be == 'baz,man,1302536204'
    end
  end
end
