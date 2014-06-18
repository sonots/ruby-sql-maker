require_relative '../spec_helper'
require 'sql/maker'

describe 'SQL::Maker' do
  context 'auto bind' do
    let(:builder) { SQL::Maker.new(:driver => 'mysql', :auto_bind => true) }

    it 'delete' do
      sql = builder.delete('foo', {:bar => "t' OR 't' = 't"})
      expect(sql).to be == %q{DELETE FROM `foo` WHERE (`bar` = 't'' OR ''t'' = ''t')}
    end

    it 'insert' do
      sql = builder.insert('foo', {:bar => "t' OR 't' = 't"})
      expect(sql).to be == %Q{INSERT INTO `foo`\n(`bar`)\nVALUES ('t'' OR ''t'' = ''t')}
    end

    it 'select' do
      sql = builder.select('foo', ['foo'], { :bar => "t' OR 't' = 't" })
      expect(sql).to be == %Q{SELECT `foo`\nFROM `foo`\nWHERE (`bar` = 't'' OR ''t'' = ''t')}
    end

    it 'update' do
      sql = builder.update('foo', {:bar => "t' OR 't' = 't"})
      expect(sql).to be == %Q{UPDATE `foo` SET `bar` = 't'' OR ''t'' = ''t'}
    end
  end

  context '#bind_param' do
    let(:builder) { SQL::Maker.new(:driver => 'mysql', :auto_bind => false) }

    it 'delete' do
      sql, bind = builder.delete('foo', {:bar => "t' OR 't' = 't"})
      sql = builder.bind_param(sql, bind)
      expect(sql).to be == %q{DELETE FROM `foo` WHERE (`bar` = 't'' OR ''t'' = ''t')}
    end
  end

  context 'hash arguments' do
    let(:builder) { SQL::Maker.new(:driver => 'mysql', :auto_bind => true) }

    it 'delete' do
      sql = builder.delete(table: 'foo', where: {:bar => "t' OR 't' = 't"})
      expect(sql).to be == %q{DELETE FROM `foo` WHERE (`bar` = 't'' OR ''t'' = ''t')}
    end

    it 'insert' do
      sql = builder.insert(table: 'foo', values: {:bar => "t' OR 't' = 't"})
      expect(sql).to be == %Q{INSERT INTO `foo`\n(`bar`)\nVALUES ('t'' OR ''t'' = ''t')}
    end

    it 'select' do
      sql = builder.select(table: 'foo', fields: ['foo'], where: { :bar => "t' OR 't' = 't" })
      expect(sql).to be == %Q{SELECT `foo`\nFROM `foo`\nWHERE (`bar` = 't'' OR ''t'' = ''t')}
    end

    it 'update' do
      sql = builder.update(table: 'foo', set: {:bar => "t' OR 't' = 't"})
      expect(sql).to be == %Q{UPDATE `foo` SET `bar` = 't'' OR ''t'' = ''t'}
    end
  end
end

describe 'SQL::Maker::Select' do
  let(:builder) { SQL::Maker::Select.new(:auto_bind => true, :new_line => ' ') }

  it 'auto bind' do
    sql = builder
      .add_select('foo')
      .add_from('table')
      .add_where('hoge' => "t' OR 't' = 't")
      .as_sql
    expect(sql).to be == %q{SELECT foo FROM table WHERE (hoge = 't'' OR ''t'' = ''t')}
  end
end

describe 'SQL::Maker::Condition' do
  let(:builder) { SQL::Maker::Condition.new(:auto_bind => true) }

  it 'auto bind' do
    sql = builder.add('hoge' => "t' OR 't' = 't").as_sql
    expect(sql).to be == %q{(hoge = 't'' OR ''t'' = ''t')}
  end
end
