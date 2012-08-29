module Wineskins
  
  module SchemaMethods
  
    def transfer_schema(opts={})
      tbls = source.tables
      tbls = tbls & opts[:include]  if opts[:include]
      tbls = tbls - opts[:exclude]  if opts[:exclude]
      tbls.each do |tbl|
        transfer_table tbl
      end
    end
    
    def transfer_table(tbl, renames=nil)
      src_tbl, dst_tbl = Array(tbl)
      dst_tbl ||= src_tbl
      renames ||= Hash[ source[src_tbl].columns.map {|col| [col,col]} ]
      this = self
      dest.create_table(dst_tbl) do
        this.source_schema(src_tbl).each do |(fld, spec)|
          column_opts = this.send(:schema_to_column_options, spec)
          if spec[:primary_key]
            primary_key renames[fld], column_opts
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
        this.source_indexes(src_tbl).each do |(name, spec)|
          index_opts = this.send(:schema_to_index_options, spec)
          index_cols = spec[:columns].map {|c| renames[c]}
          add_index index_cols, index_opts.merge(:name => name)
        end
      end
    end
    
    # note no renaming of target table
    # also more complicated scenarios (multi-column, non-numeric keys etc) 
    # are not yet tested
    def transfer_foreign_keys(tbl, renames=nil)
      src_tbl, dst_tbl = Array(tbl)
      dst_tbl ||= src_tbl
      renames ||= Hash[ source[src_tbl].columns.map {|col| [col,col]} ]
      this = self
      dest.alter_table(dst_tbl) do
        this.source_foreign_key_list(src_tbl).each do |spec|
          fk_opts = this.send(:schema_to_foreign_key_options, spec)
          fk_cols = spec[:columns].map {|c| renames[c]}
          add_foreign_key fk_cols, spec[:table], fk_opts
        end
      end
    end
    
    def source_schema(tbl,opts={})
      source.schema(tbl,opts)
    rescue Sequel::Error
      warn "Source database does not expose schema metadata. " +
           "You should define schema manually."
      []
    end
    
    def source_indexes(tbl,opts={})
      source.indexes(tbl,opts)
    rescue Sequel::Error
      warn "Source database does not expose index metadata. " +
           "You should define indexes manually."
      {}      
    end
    
    def source_foreign_key_list(tbl,opts={})
      source.foreign_key_list(tbl,opts)
    rescue Sequel::Error
      warn "Source database does not expose foreign key metadata. " +
           "You should define foreign key constraints manually."
      []
    end
    
    private
    
    def schema_to_column_options(spec)
      Utils.remap_hash spec,
        {:db_type     => :type,
         :primary_key => :primary_key,
         :default     => :default,
         :allow_null  => :null
        }
    end
    
    def schema_to_index_options(spec)
      Utils.remap_hash spec,
        {:unique => :unique,
         :type   => :type,
         :where  => :where
        }
    end
    
    def schema_to_foreign_key_options(spec)
      Utils.remap_hash spec,
        {:key        => :key,
         :deferrable => :deferrable,
         :name       => :name,
         :on_delete  => :on_delete,
         :on_update  => :on_update
        }
    end
    
  end

end