require File.expand_path('./helper', File.dirname(__FILE__))
require File.expand_path('../lib/wineskins', File.dirname(__FILE__))

TEST_DB.setup

module TransferRecordsTestHelpers

  def setup_source
    TEST_DB.source.create_table! :users do
      primary_key :uid
      String :username
      DateTime :joined_at
    end
    
    TEST_DB.source.create_table! :tests do
      primary_key :id
      String :name
      Integer :score, :index => true
      DateTime :taken_at
      index :name
      foreign_key :user_id, :users, :on_delete => :cascade
    end
    
    TEST_DB.source[:users].multi_insert([
      {:uid => 1, :username => "Wilson", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 2, :username => "Abner",  :joined_at => Time.now - rand(60*60*24)},
      {:uid => 3, :username => "Penelope", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 4, :username => "Harrison", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 5, :username => "Luke", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 6, :username => "Kramer", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 7, :username => "Gjert", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 8, :username => "Yvette", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 9, :username => "Ruth", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 10, :username => "Lambert", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 11, :username => "Percy", :joined_at => Time.now - rand(60*60*24)}
    ])

    TEST_DB.source[:tests].multi_insert([
      {:id => 1, :name => 'test1', :score => 65, :taken_at => Time.now - rand(60*60*24)},
      {:id => 2, :name => 'test2', :score => 21, :taken_at => Time.now - rand(60*60*24)},
      {:id => 3, :name => 'test3', :score => 75, :taken_at => Time.now - rand(60*60*24)},
      {:id => 4, :name => 'test4', :score => 84, :taken_at => Time.now - rand(60*60*24)},
      {:id => 5, :name => 'test5', :score => 60, :taken_at => Time.now - rand(60*60*24)},
      {:id => 6, :name => 'test6', :score => 20, :taken_at => Time.now - rand(60*60*24)},
      {:id => 7, :name => 'test7', :score => 66, :taken_at => Time.now - rand(60*60*24)},
      {:id => 8, :name => 'test8', :score => 87, :taken_at => Time.now - rand(60*60*24)},
      {:id => 9, :name => 'test9', :score => 72, :taken_at => Time.now - rand(60*60*24)},
      {:id => 10, :name => 'test10', :score => 33, :taken_at => Time.now - rand(60*60*24)},
      {:id => 11, :name => 'test11', :score => 99, :taken_at => Time.now - rand(60*60*24)}
    ])
    
  end
  
  def setup_dest
  
    TEST_DB.dest.create_table! :users do
      primary_key :uid
      String :username
      DateTime :joined_at
    end
  
    TEST_DB.dest.create_table! :users2 do
      primary_key :uid
      String :username
      DateTime :joined_at    
    end
    
    TEST_DB.dest.create_table! :tests do
      primary_key :test_id
      String :test_name
      Integer :test_score, :index => true
      DateTime :test_taken_at
      index :test_name
      foreign_key :test_user_id, :users, :on_delete => :cascade
    end
    
  end
  
end

describe 'transfer_records, functional' do
  subject { Wineskins::Transfer.new(source, dest) }
  let(:source) { TEST_DB.source }
  let(:dest)   { TEST_DB.dest   }
  
  include TransferRecordsTestHelpers  
  before do
    setup_source
    setup_dest
  end

  it 'should insert records matching source' do
    subject.transfer_records :users
    exp = source[:users].all.sort {|a,b| a[:uid] <=> b[:uid]}
    act = dest[:users].all.sort   {|a,b| a[:uid] <=> b[:uid]}
    refute_empty act
    assert_equal exp, act
  end

  describe 'when table renamed' do
    include TransferRecordsTestHelpers  
    before do
      setup_source
      setup_dest
    end

    it 'should insert records matching source' do
      subject.transfer_records [:users, :users2]
      exp = source[:users].all.sort {|a,b| a[:uid] <=> b[:uid]}
      act = dest[:users2].all.sort   {|a,b| a[:uid] <=> b[:uid]}
      refute_empty act
      assert_equal exp, act
    end
    
  end

  describe 'when fields renamed' do
    include TransferRecordsTestHelpers  
    before do
      setup_source
      setup_dest
    end
    
    it 'should insert records matching source, mapping field names' do
      subject.transfer_records :tests,
        :id => :test_id,
        :name => :test_name,
        :score => :test_score,
        :taken_at => :test_taken_at

      exp = source[:tests].all.sort {|a,b| a[:uid] <=> b[:uid]}
      act = dest[:tests].all.sort   {|a,b| a[:uid] <=> b[:uid]}
      refute_empty act
      assert_equal exp.length, act.length
      exp.each_with_index do |rec, i|
        assert_equal rec[:id], act[i][:test_id]
        assert_equal rec[:name], act[i][:test_name]
        assert_equal rec[:score], act[i][:test_score]
        assert_equal rec[:taken_at], act[i][:test_taken_at]
      end
    end
    
  end
  
  describe 'when block passed' do
    include TransferRecordsTestHelpers  
    before do
      setup_source
      setup_dest
    end
    
    it 'should insert records matching source, mapping field names' do
      subject.transfer_records :tests do |rec|
        Hash[
          rec.map {|k,v|
            ["test_#{k}", v]
          }
        ]
      end

      exp = source[:tests].all.sort {|a,b| a[:uid] <=> b[:uid]}
      act = dest[:tests].all.sort   {|a,b| a[:uid] <=> b[:uid]}
      refute_empty act
      assert_equal exp.length, act.length
      exp.each_with_index do |rec, i|
        assert_equal rec[:id], act[i][:test_id]
        assert_equal rec[:name], act[i][:test_name]
        assert_equal rec[:score], act[i][:test_score]
        assert_equal rec[:taken_at], act[i][:test_taken_at]
      end
    end
    
  end
  
end