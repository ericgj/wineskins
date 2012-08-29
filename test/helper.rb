gem 'minitest'
require 'minitest/autorun'

require 'logger'

class << (TEST_DB = Object.new)
  def source 
    @source ||= Sequel.connect('sqlite://test/fixtures/db/source.sqlite3')
  end
  
  def dest   
    @dest ||= Sequel.connect('sqlite://test/fixtures/db/dest.sqlite3')
  end

  def source_ado
    @source_ado ||= begin
      dir = File.expand_path("fixtures/db/", 
                             File.dirname(__FILE__)
                            ).tr('/','\\')
      conn_string = \
        "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=#{dir}/source-ado.mdb;Jet OLEDB:System Database=#{dir}/source-ado.mdw;User ID=Admin;Password=admin!;"
      Sequel.ado(:conn_string => conn_string)
    end
  end
  
  def setup
    source.loggers << ::Logger.new('test/log/source.log')
    dest.loggers << ::Logger.new('test/log/dest.log')
  end
  
  def setup_ado
    source_ado.loggers << ::Logger.new('test/log/source-ado.log')
  end
  
end

class SequelSpec < MiniTest::Spec
  def run(*args, &block)
    TEST_DB.dest.transaction(:rollback => :always){super}
  end
end

MiniTest::Spec.register_spec_type(/functional/i, SequelSpec)