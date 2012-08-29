require File.expand_path('./helper', File.dirname(__FILE__))
require File.expand_path('../lib/wineskins', File.dirname(__FILE__))

TEST_DB.setup

module TransferTableTestHelpers
  def setup_source
    TEST_DB.source.create_table! :users do
      primary_key :uid
      String :username
      Time :joined_at
    end
    
    TEST_DB.source.create_table! :tests do
      primary_key :id
      String :name
      Integer :count, :index => true
      index :name, :name => :name_index_poo, :unique => true
      foreign_key :user_id, :users, :on_delete => :cascade
    end
  end
  
  def setup_dest
    TEST_DB.dest.create_table! :users do
      primary_key :uid
      String :username
      Time :joined_at
    end
  end
  
end

describe 'transfer_table, functional' do
  include TransferTableTestHelpers
  
  subject { Wineskins::Transfer.new(source, dest) }
  let(:source) { TEST_DB.source }
  let(:dest)   { TEST_DB.dest   }
  
  before do
    setup_source
    setup_dest
  end
  
  it 'should create a table in dest' do
    subject.transfer_table :tests
    assert_includes dest.tables, :tests 
  end
  
  it 'should match schema specs in source' do
    subject.transfer_table :tests
    assert_equal source.schema(:tests), dest.schema(:tests)
  end

  it 'should match index specs in source' do
    subject.transfer_table :tests
    assert_equal source.indexes(:tests), dest.indexes(:tests)
  end
  
  it 'should match foreign key specs in source' do
    subject.transfer_table :tests
    assert_equal source.foreign_key_list(:tests), dest.foreign_key_list(:tests)
  end
  
  describe 'when table renamed' do
    include TransferTableTestHelpers
    before do
      setup_source
      setup_dest
    end

    it 'should create a table in dest with new name' do
      subject.transfer_table [:tests, :specs]
      assert_includes dest.tables, :specs 
    end
  
    it 'should match schema specs in source' do
      subject.transfer_table [:tests, :specs]
      assert_equal source.schema(:tests), dest.schema(:specs)
    end
    
    it 'should match index specs in source' do
      subject.transfer_table [:tests, :specs]
      assert_equal source.indexes(:tests), dest.indexes(:specs)
    end

    it 'should match foreign key specs in source' do
      subject.transfer_table [:tests, :specs]
      assert_equal source.foreign_key_list(:tests), dest.foreign_key_list(:specs)
    end
    
  end
  
  describe 'when fields renamed' do
    include TransferTableTestHelpers
    before do
      setup_source
      setup_dest
    end

    it 'should create a table in dest' do
      subject.transfer_table :tests, 
        :id => :test_id, :name => :test_name, :count => :test_count, 
        :user_id => :test_user_id
      assert_includes dest.tables, :tests 
    end
    
    it 'each field should match schema specs in source' do
      subject.transfer_table :tests, 
        :id => :test_id, :name => :test_name, :count => :test_count, 
        :user_id => :test_user_id
      source.schema(:tests).each_with_index do |(fld, specs), i|
        assert_equal specs, dest.schema(:tests)[i][1]
      end
      assert_equal source.schema(:tests).length, dest.schema(:tests).length
    end

    it 'each index should match specs in source' do
      subject.transfer_table :tests, 
        :id => :test_id, :name => :test_name, :count => :test_count, 
        :user_id => :test_user_id
      source.indexes(:tests).each_with_index do |(iname, specs), i|
        refute_nil dest.indexes(:tests)[iname]
        assert_equal specs[:unique], dest.indexes(:tests)[iname][:unique]
      end
      assert_equal source.indexes(:tests).length, dest.indexes(:tests).length
    end

    it 'foreign key should match specs in source' do
      subject.transfer_table :tests, 
        :id => :test_id, :name => :test_name, :count => :test_count, 
        :user_id => :test_user_id
      exp = source.foreign_key_list(:tests).find {|specs| 
                                              specs[:columns] == [:user_id]
                                            }
      act = dest.foreign_key_list(:tests).find {|specs| 
                                              specs[:columns] == [:test_user_id]
                                            }
      refute_nil act                                      
      assert_equal exp[:table], act[:table]
      assert_equal exp[:key],   act[:key]
      assert_equal source.foreign_key_list(:tests).length, 
                   dest.foreign_key_list(:tests).length
    end
    
  end
  
end
