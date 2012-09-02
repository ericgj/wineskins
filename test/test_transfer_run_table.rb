require File.expand_path('helper', File.dirname(__FILE__))
require File.expand_path('helpers/transfer_assertions', File.dirname(__FILE__))
require File.expand_path('../lib/wineskins', File.dirname(__FILE__))

TEST_DB.source_connect = 'sqlite://test/fixtures/db/source.sqlite3'
TEST_DB.dest_connect   = 'sqlite://test/fixtures/db/dest.sqlite3'

describe 'Transfer#run, default global options, functional' do

  subject { Wineskins::Transfer.new(source,dest) }
  let(:source) { TEST_DB.source }
  let(:dest)   { TEST_DB.dest }
  
  #------------------------------------------
  describe 'single table, default options' do
    include TransferAssertions
    
    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest   :users, :test_categories
      subject.define do
        table :tests
      end.run
    end
    
    it 'should create a table in dest' do
      assert_includes dest.tables, :tests 
    end
    
    it 'should match schema specs in source' do
      assert_columns_match(:tests)
    end

    it 'should match index specs in source' do
      assert_indexes_match(:tests)
    end
    
    it 'should match foreign key specs in source' do
      assert_fk_match(:tests)
    end
  
    it 'should have the same number of records as in source' do
      assert_equal source[:tests].count, dest[:tests].count
    end
    
    it 'should have the same range of primary keys as in source' do
      assert_equal source[:tests].get{max(id)}, dest[:tests].get{max(id)}
      assert_equal source[:tests].get{min(id)}, dest[:tests].get{min(id)}
    end
  end
  
  #------------------------------------------
  describe 'multiple tables, default options' do
    include TransferAssertions
    
    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest
      subject.define do
        table :test_categories
        table :users
        table :tests
      end.run
    end
    
    it 'should create tables in dest' do
      assert_includes dest.tables, :test_categories 
      assert_includes dest.tables, :users 
      assert_includes dest.tables, :tests 
    end
    
    it 'should match schema specs in source' do
      assert_columns_match(:test_categories)
      assert_columns_match(:users)
      assert_columns_match(:tests)
    end

    it 'should match index specs in source' do
      assert_indexes_match(:test_categories)
      assert_indexes_match(:users)
      assert_indexes_match(:tests)
    end
    
    it 'should match foreign key specs in source' do
      assert_fk_match(:test_categories)
      assert_fk_match(:users)
      assert_fk_match(:tests)
    end
  
    it 'each table should have the same number of records as in source' do
      assert_equal source[:test_categories].count, dest[:test_categories].count
      assert_equal source[:users].count, dest[:users].count
      assert_equal source[:tests].count, dest[:tests].count
    end
    
    it 'each table should have the same range of primary keys as in source' do
      assert_equal source[:test_categories].get{max(id)}, dest[:test_categories].get{max(id)}
      assert_equal source[:test_categories].get{min(id)}, dest[:test_categories].get{min(id)}

      assert_equal source[:users].get{max(uid)}, dest[:users].get{max(uid)}
      assert_equal source[:users].get{min(uid)}, dest[:users].get{min(uid)}

      assert_equal source[:tests].get{max(id)}, dest[:tests].get{max(id)}
      assert_equal source[:tests].get{min(id)}, dest[:tests].get{min(id)}
    end
  end
  

  #------------------------------------------
  describe 'single table, rename columns with hash' do
    include TransferAssertions
    
    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest   :users, :test_categories
      subject.define do
        table :tests do
          rename :user_id => :uid, :name => :testname
        end
      end.run
    end  
    
    it 'should match schema specs in source, with renamed columns' do
      assert_column_matches(:tests, [:user_id, :uid])
      assert_column_matches(:tests, [:name, :testname])
      [:score, :taken_at, :cat_id].each do |col|
        assert_column_matches(:tests, col)
      end
    end

    it 'should match index specs in source, with renamed columns' do
      assert_index_matches(:tests, [:name], {:name => :testname})
      assert_index_matches(:tests, [:score])
    end

    it 'should match foreign key specs in source, with renamed columns' do
      assert_fk_matches(:tests, [:user_id], {:user_id => :uid})
      assert_fk_matches(:tests, [:cat_id])
    end
    
  end
  
  #------------------------------------------
  describe 'single table, alternative column options passed for existing columns' do
    include TransferAssertions
    
    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest   :users, :test_categories
      subject.define do
        table :tests do
          column :id, :integer
          column :name, :text, :null => false, :default => 'unknown'
        end
      end.run
    end

    it 'should match passed specs for alternate columns, and source specs for other columns' do
      assert_column_matches(:tests, :id, 
        {:allow_null => true, :primary_key => false, :default => nil}
      )
      assert_column_matches(:tests, :name,
        {:allow_null => false, :primary_key => false, :default => "'unknown'"}
      )
      [:score, :taken_at, :cat_id].each do |col|
        assert_column_matches(:tests, col)
      end      
    end
    
  end
  
end