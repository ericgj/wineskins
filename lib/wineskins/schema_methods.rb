module Wineskins
  
  module SchemaMethods
  
    def transfer_table(table)
      src_tbl, dst_tbl = table.source_name, table.dest_name
      rename = table.rename_map(source[src_tbl].columns)
      this = self
      dest.create_table(dst_tbl) do
        this.source_schema(src_tbl).each do |(fld, spec)|
          column_opts = this.schema_to_column_options(spec)
          if spec[:primary_key]
            primary_key rename[fld], column_opts
          else
            column rename[fld], spec[:type], column_opts
          end
        end
      end
    end
    
    def transfer_indexes(table)
      src_tbl, dst_tbl = table.source_name, table.dest_name
      rename = table.rename_map(source[src_tbl].columns)
      this = self
      dest.alter_table(dst_tbl) do
        this.source_indexes(src_tbl).each do |(name, spec)|
          index_opts = this.schema_to_index_options(spec)
          index_cols = spec[:columns].map {|c| rename[c]}
          add_index index_cols, index_opts
        end
      end
    end
    
    def transfer_fk_constraints(table, table_rename={})
      src_tbl, dst_tbl = table.source_name, table.dest_name
      rename = table.rename_map(source[src_tbl].columns)
      this = self
      dest.alter_table(dst_tbl) do
        this.source_foreign_key_list(src_tbl).each do |spec|
          fk_opts = this.schema_to_foreign_key_options(spec)
          fk_cols = spec[:columns].map {|c| rename[c]}
          add_foreign_key fk_cols, table_rename[spec[:table]] || spec[:table], fk_opts
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

    
    def schema_to_column_options(spec)
      Utils.limit_hash spec, [
        :default,
        :allow_null
      ]
    end
    
    def schema_to_index_options(spec)
      Utils.limit_hash spec, [:unique]
    end
    
    def schema_to_foreign_key_options(spec)
      Utils.limit_hash spec, [
        :key,
        :deferrable,
        :name,
        :on_delete,
        :on_update
      ]
    end
    
  end

end