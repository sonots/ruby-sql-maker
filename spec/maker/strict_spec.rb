require_relative '../spec_helper'
require 'sql/maker'

describe 'SQL::Maker' do
  include SQL::Maker::Helper

  let(:maker) do
    SQL::Maker.new(
      :driver => 'SQLite',
      :strict => true,
    )
  end

  it { expect(maker.strict).to be == true }

  it "maker.new_condition" do
    expect { maker.new_condition.add(:foo => [1]) }.to raise_error(SQL::Maker::Error)
    expect { maker.new_condition.add(:foo => {'!=' => ''}) }.to raise_error(SQL::Maker::Error)
  end

  it "select.new_condition" do
    select = maker.new_select
    expect(select.strict).to be == true
    expect { select.new_condition.add(:foo => [1]) }.to raise_error(SQL::Maker::Error)
  end

  it "maker.select" do
    expect { maker.select("user", ['*'], { :name => ["John", "Tom" ]}) }.to raise_error(SQL::Maker::Error)
  end

  context "maker.insert" do
    it "raise error by strict mode" do
      expect { maker.insert(
          :user, { :name => "John", :created_on => ["datetime(now)"] }
      ) }.to raise_error(SQL::Maker::Error)
    end

    it "using term" do
      sql, binds = maker.insert(:user, { :name => "John", :created_on => sql_raw("datetime(now)") })
      expect(sql).to be == %Q{INSERT INTO "user"\n("name", "created_on")\nVALUES (?, datetime(now))}
      expect(binds.join(',')).to be == 'John'
    end
  end

  it "maker.delete" do
    expect { maker.delete(:user, { :name => ["John", "Tom"]}) }.to raise_error(SQL::Maker::Error)
  end

  context "maker.update where" do
    it "raise error by strict mode" do
      expect { maker.update(:user, {:name => "John"}, { :user_id => [1, 2] }) }.to raise_error(SQL::Maker::Error)
    end

    it "using term" do
      sql, binds = maker.update(:user, {:name => "John"}, { :user_id => sql_in([1, 2]) })
      expect(sql).to be == %Q{UPDATE "user" SET "name" = ? WHERE ("user_id" IN (?,?))}
      expect(binds.join(',')).to be == 'John,1,2'
    end
  end

  it "maker.update set" do
    expect { sql, bind = maker.update(:user, {:name => ["select *"]}) }.to raise_error(SQL::Maker::Error)
  end
end
