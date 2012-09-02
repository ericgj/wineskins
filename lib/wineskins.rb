require 'sequel'
require File.expand_path('sequel_ext/adapters/shared/access', File.dirname(__FILE__))

require File.expand_path('wineskins/version', File.dirname(__FILE__))
require File.expand_path('wineskins/utils', File.dirname(__FILE__))
require File.expand_path('wineskins/schema_methods', File.dirname(__FILE__))
require File.expand_path('wineskins/record_methods', File.dirname(__FILE__))

module Wineskins

  def self.run(source, dest, &block)
    Transfer.new(source, dest, &block).run
  end
    
  class Transfer
    include SchemaMethods
    include RecordMethods
    
    attr_accessor :source, :dest, :tables
    
    def initialize(source, dest, &block)
      self.source = source
      self.dest = dest
      @tables = []
      self.define(&block) if block_given?
    end

    def define(&block)
      instance_eval(&block)
      self
    end
    
    def run
      dest.transaction do
        create_tables!
        create_indexes!
        create_fk_constraints!
        insert_records!
      end
    end
    
    def table(name, opts={}, &block)
      @tables << Table.new(name, opts, &block)
    end
    
    private
    
    def create_tables!
      @tables.select {|t| t.create_table?}.each do |table|
        transfer_table table
      end
    end
    
    def create_indexes!
      @tables.select {|t| t.create_indexes?}.each do |table|
        transfer_indexes table
      end
    end
    
    def create_fk_constraints!
      @tables.select {|t| t.create_fk_constraints?}.each do |table|
        transfer_fk_constraints table, table_rename
      end
    end
    
    def insert_records!
      @tables.select {|t| t.insert_records?}.each do |table|
        transfer_records table
      end
    end
    
    # used in create_fk_constraints
    def table_rename
      @tables.inject({}) do |memo, table|
        memo[table.source_name] = table.dest_name
        memo
      end
    end
    
  end
  
  # data structure for table transfer definition
  class Table
  
    attr_accessor :source_name, :dest_name
    
    attr_accessor :include, 
                  :exclude, 
                  :rename, 
                  :create_table, 
                  :create_indexes, 
                  :create_fk_constraints, 
                  :insert_records
       
    def initialize(name, opts={}, &block)
      self.source_name, self.dest_name = Array(name)
      self.dest_name ||= self.source_name
      Builder.new(self, default_opts.merge(opts), &block)
    end
    
    
    def create_table?
      !!create_table
    end
    
    def create_indexes?
      !!create_indexes
    end

    def create_fk_constraints?
      !!create_fk_constraints
    end
    
    def insert_records?
      !!insert_records
    end
    
    # todo: handle Proc or Regex === rename
    def rename_map(cols)
      col_map = cols.inject({}) {|m,c| m[c]=c;m}
      col_map.merge(rename)
    end
    
    def default_opts
      { include:                nil,
        exclude:                [],
        rename:                 {},
        create_table:           true,
        create_indexes:         true,
        create_fk_constraints:  true,
        insert_records:         true
      }
    end
    

    class Builder
                              
      def initialize(target, opts={}, &block)
        @target = target
        set_options opts
        instance_eval(&block) if block_given?
      end        
      
      def include(flds)
        @target.include = flds
      end
      
      def exclude(flds)
        @target.exclude = flds
      end
      
      def rename(fldmap=nil, &block)
        @target.rename = fldmap || block
      end
      
      def create_table(bool=true)
        @target.create_table = bool
      end
      
      def create_indexes(bool=true)
        @target.create_indexes = bool
      end

      def create_fk_constraints(bool=true)
        @target.create_fk_constraints = bool
      end
      
      def insert_records(bool=true)
        @target.insert_records = bool
      end
      
      def set_options(opts)
        [:include, :exclude, :rename, 
         :create_table, :create_indexes, :create_fk_constraints, :insert_records
        ].each do |opt|
          self.send(opt, opts[opt]) if opts[opt]
        end 
      end
          
    end
    
  end
  
end

