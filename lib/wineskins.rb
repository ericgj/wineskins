require 'sequel'

# Modification of ADO/Access adapter to get schema info
# incorporated into Sequel itself v3.39.0
# require File.expand_path('sequel_ext/adapters/shared/access', File.dirname(__FILE__))

require File.expand_path('wineskins/version', File.dirname(__FILE__))
require File.expand_path('wineskins/utils', File.dirname(__FILE__))
require File.expand_path('wineskins/transcript', File.dirname(__FILE__))
require File.expand_path('wineskins/schema_methods', File.dirname(__FILE__))
require File.expand_path('wineskins/record_methods', File.dirname(__FILE__))

module Wineskins

  def self.transfer(source, dest, opts={}, &block)
    Transfer.new(source, dest, &block).run(opts)
  end
    
  class Transfer
    include SchemaMethods
    include RecordMethods
    
    attr_accessor :source, :dest
    attr_reader :table_defs, :progressbar
    attr_reader :before_hooks, :after_hooks
    
    def initialize(source, dest, &block)
      self.source = source
      self.dest = dest
      @table_defs = []
      @before_hooks = Hash.new{|h,k|h[k]=[]}
      @after_hooks = Hash.new{|h,k|h[k]=[]}
      self.define(&block) if block_given?
    end

    def define(&block)
      instance_eval(&block)
      self
    end
    
    def run(opts={})
      rollback = (opts[:dryrun] ? :always : nil)
      dest.transaction(:rollback => rollback) do
        trigger_before_hooks
        trigger_before_hooks :create_tables
        create_tables!
        trigger_after_hooks :create_tables
        trigger_before_hooks :create_indexes
        create_indexes!
        trigger_after_hooks :create_indexes
        trigger_before_hooks :create_fk_constraints
        create_fk_constraints!
        trigger_after_hooks :create_fk_constraints
        trigger_before_hooks :insert_records
        insert_records!
        trigger_after_hooks :insert_records
        trigger_after_hooks
      end
    end
    
    def transcript(file=nil)
      self.dest.loggers << Transcript.new(file)
    end
    
    def tables(*args)
      opts = (Hash === args.last ? args.pop : {})
      tbls = (args.empty? ? self.source.tables : args)
      tbls.each do |tbl| table(tbl, opts) end
    end
    
    def table(name, opts={}, &block)
      @table_defs << Table.new(name, opts, &block)
    end
    
    def before(event=nil, &cb)
      before_hooks[event] << cb
    end
    
    def after(event=nil, &cb)
      after_hooks[event] << cb
    end
    
    [:before, 
     :after
    ].product([
     :create_tables, 
     :create_indexes, 
     :create_fk_constraints, 
     :insert_records
    ]).each do |(hook, event)|
      define_method("#{hook}_#{event}") do |&block|
        send hook, event, &block
      end
    end
      
    def set_progressbar(title, total)
      require 'progressbar'
      @progressbar = ProgressBar.new(title, total)
    rescue LoadError
      @progressbar = nil
    end
    
    private
    
    def create_tables!
      @table_defs.select {|t| t.create_table?}.each do |table|
        transfer_table table
      end
    end
    
    def create_indexes!
      @table_defs.select {|t| t.create_indexes?}.each do |table|
        transfer_indexes table
      end
    end
    
    def create_fk_constraints!
      @table_defs.select {|t| t.create_fk_constraints?}.each do |table|
        transfer_fk_constraints table, table_rename
      end
    end
    
    def insert_records!
      @table_defs.select {|t| t.insert_records?}.each do |table|
        transfer_records table
      end
    end
    
    # used in create_fk_constraints
    def table_rename
      @table_defs.inject({}) do |memo, table|
        memo[table.source_name] = table.dest_name
        memo
      end
    end
    
    def trigger_before_hooks(event=nil)
      before_hooks[event].each do |cb|
        cb.call
      end
    end

    def trigger_after_hooks(event=nil)
      after_hooks[event].each do |cb|
        cb.call
      end
    end
    
  end
  
  # data structure for table transfer definition
  class Table
  
    attr_accessor :source_name, :dest_name, :dest_columns
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
      self.dest_columns = {}
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
         
      def column(name, *args)
        @target.dest_columns[name] = args
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
      
      def schema_only
        create_table; create_indexes; create_fk_constraints
        insert_records false
      end
      
      def records_only
        create_table(false); create_indexes(false); create_fk_constraints(false)
        insert_records
      end
      
      def set_options(opts)
        [:include, :exclude, :rename, 
         :create_table, :create_indexes, :create_fk_constraints, :insert_records,
        ].each do |opt|
          self.send(opt, opts[opt]) if opts[opt]
        end 
        [:schema_only,  :records_only].each do |opt|
          self.send(opt) if opts[opt]
        end
      end
          
    end
    
  end
  
end

