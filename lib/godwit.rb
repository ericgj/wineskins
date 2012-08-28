require 'sequel'

module Godwit

  class Transfer
    
    attr_accessor :source, :dest
    
    def initialize(source, dest)
      self.source = source
      self.dest = dest
    end

    def transfer_table(tbl, renames=nil)
      src_tbl, dst_tbl = Array(tbl)
      dst_tbl ||= src_tbl
      renames ||= Hash[ source[src_tbl].columns.map {|col| [col,col]} ]
      this = self
      dest.create_table(dst_tbl) do
        this.source.schema(src_tbl).each do |(fld, spec)|
          column_opts = this.send(:schema_to_column_options, spec)
          if spec[:primary_key]
            primary_key renames[fld]
          else
            column renames[fld], column_opts.delete(:type), column_opts
          end
        end
      end
      transfer_indexes(tbl, renames)
      transfer_foreign_keys(tbl, renames)
    end
    
    # note that renames only maps source to dest columns names, 
    # not the index names
    def transfer_indexes(tbl, renames=nil)
      src_tbl, dst_tbl = Array(tbl)
      dst_tbl ||= src_tbl
      renames ||= Hash[ source[src_tbl].columns.map {|col| [col,col]} ]
      this = self
      dest.alter_table(dst_tbl) do
        this.source.indexes(src_tbl).each do |(name, spec)|
          index_opts = this.send(:schema_to_index_options, spec)
          index_cols = spec[:columns].map {|c| renames[c]}
          add_index index_cols, index_opts.merge(:name => name)
        end
      end
    end
    
    def transfer_foreign_keys(tbl, renames=nil)
      src_tbl, dst_tbl = Array(tbl)
      dst_tbl ||= src_tbl
      renames ||= Hash[ source[src_tbl].columns.map {|col| [col,col]} ]
      this = self
      dest.alter_table(dst_tbl) do
        this.source.foreign_key_list(src_tbl).each do |spec|
          fk_opts = this.send(:schema_to_foreign_key_options, spec)
          fk_cols = spec[:columns].map {|c| renames[c]}
          add_foreign_key fk_cols, spec[:table], fk_opts
        end
      end
    end
    
    private
    def schema_to_column_options(spec)
      map_to_options spec,
        {:db_type     => :type,
         :primary_key => :primary_key,
         :default     => :default,
         :allow_null  => :null
        }
    end
    
    def schema_to_index_options(spec)
      map_to_options spec,
        {:unique => :unique,
         :type   => :type,
         :where  => :where
        }
    end
    
    def schema_to_foreign_key_options(spec)
      map_to_options spec,
        {:key        => :key,
         :deferrable => :deferrable,
         :name       => :name,
         :on_delete  => :on_delete,
         :on_update  => :on_update
        }
    end
    
    def map_to_options(spec, map)
      map.inject({}) do |memo, (in_key, out_key)|
        memo[out_key] = spec[in_key] if spec[in_key]
        memo
      end
    end
    
  end
  
end

