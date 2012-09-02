gem 'minitest'
require 'minitest/autorun'

class SequelSpec < MiniTest::Spec
  def run(*args, &block)
    TEST_DB.dest.transaction(:rollback => :always){super}
  end
end

MiniTest::Spec.register_spec_type(/functional/i, SequelSpec)


require 'logger'

class << (TEST_DB = Object.new)

  attr_accessor :source_connect, :dest_connect
  
  def source
    @source ||= Sequel.connect(source_connect)
  end

  def dest
    @dest ||= Sequel.connect(dest_connect)
  end
  
  def setup_source(*tables)
    source.loggers = [::Logger.new('test/log/source.log')]
    setup source, *tables
  end
  
  def setup_dest(*tables)
    dest.loggers = [::Logger.new('test/log/dest.log')]
    setup dest, *tables
  end
  
  def setup(db, *tables)
    tables.each do |t|
      TEST_SCHEMA.send(t, db)
      db[t].multi_insert(
        TEST_DATA[t]
      )
    end
  end
  
end

class << (TEST_SCHEMA = Object.new)

  def tests(db)
    db.create_table! :tests do
      primary_key :id
      column :name, :string
      column :score, :integer, :index => true
      column :taken_at, :datetime
      index :name, :unique => true
      foreign_key :user_id, :users, :on_delete => :cascade
      foreign_key :cat_id, :test_categories, :on_update => :cascade
    end
  end
  
  def users(db)
    db.create_table! :users do
      primary_key :uid
      column :username, :string
      column :joined_at, :datetime
    end
  end
  
  def test_categories(db)
    db.create_table! :test_categories do
      primary_key :id
      column :name, :string
      column :desc, :string
    end
  end
  
end

TEST_DATA = {

  :tests => [
    {:id => 1, :name => 'test1', :score => 65, :taken_at => Time.now - rand(60*60*24),
     :user_id => 11, :cat_id => 1},
    {:id => 2, :name => 'test2', :score => 21, :taken_at => Time.now - rand(60*60*24),
     :user_id => 10, :cat_id => 1},
    {:id => 3, :name => 'test3', :score => 75, :taken_at => Time.now - rand(60*60*24),
     :user_id =>  9, :cat_id => 1},
    {:id => 4, :name => 'test4', :score => 84, :taken_at => Time.now - rand(60*60*24),
     :user_id =>  8, :cat_id => 2},
    {:id => 5, :name => 'test5', :score => 60, :taken_at => Time.now - rand(60*60*24),
     :user_id =>  7, :cat_id => 3},
    {:id => 6, :name => 'test6', :score => 20, :taken_at => Time.now - rand(60*60*24),
     :user_id =>  1, :cat_id => 1},
    {:id => 7, :name => 'test7', :score => 66, :taken_at => Time.now - rand(60*60*24),
     :user_id =>  1, :cat_id => 2},
    {:id => 8, :name => 'test8', :score => 87, :taken_at => Time.now - rand(60*60*24),
     :user_id =>  2, :cat_id => 2},
    {:id => 9, :name => 'test9', :score => 72, :taken_at => Time.now - rand(60*60*24),
     :user_id =>  4, :cat_id => 3},
    {:id => 10, :name => 'test10', :score => 33, :taken_at => Time.now - rand(60*60*24),
     :user_id =>  5, :cat_id => 1},
    {:id => 11, :name => 'test11', :score => 99, :taken_at => Time.now - rand(60*60*24),
     :user_id =>  8, :cat_id => 1}  
  ],
  
  :users => [
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
  ],
  
  :test_categories => [
    {:id  => 1, :name => 'first', :desc => 'first test'},
    {:id  => 2, :name => 'second', :desc => 'second test'},
    {:id  => 3, :name => 'third'}
  ]
  
}

