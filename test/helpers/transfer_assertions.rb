module TransferAssertions
  
  # I wish we could compare :type as well, but this seems somewhat adapter-
  # dependent. Probably :default is adapter-dependent too.
  #
  def assert_columns_match(table)
    match_keys = [:allow_null, :primary_key, :default]
    exp = source.schema(table).map {|name, col| 
            [name, Wineskins::Utils.limit_hash(col, match_keys)]
          }
    act = dest.schema(table).map {|name, col| 
            [name, Wineskins::Utils.limit_hash(col, match_keys)]
          }
    assert_equal exp.length, act.length,
      "Expected #{exp.length} columns in table #{table}, got #{act.length}"
    exp.each do |col|
      assert_includes act, col,
        "Unexpected column options for #{col[0]} in table #{table}"
    end
  end
  
  def assert_column_matches(table, col, specs=nil)
    src_col, dst_col = Array(col)
    dst_col ||= src_col
    exp = if specs 
            [src_col, specs]
          else
            source.schema(table).find {|name,col| name == src_col}
          end
    act = dest.schema(table).find {|name,col| name == dst_col}
    refute_nil act, "Expected column #{dst_col} not found in table #{table}"
    
    match_keys = [:allow_null, :primary_key, :default]
    exp = [exp[0], Wineskins::Utils.limit_hash( exp[1], match_keys )]
    act = [act[0], Wineskins::Utils.limit_hash( act[1], match_keys )]
    assert_equal exp[1], act[1],
      "Unexpected column options for #{dst_col} in table #{table}"
  end
  
  def assert_indexes_match(table)
    exp, act = source.indexes(table), dest.indexes(table)
    assert_equal exp.length, act.length, 
      "Expected #{exp.length} indexes for table #{table}, got #{act.length}"
    exp.values.each do |idx|
      assert_includes act.values, idx,
        "Unexpected index options in table #{table}"
    end
  end
  
  def assert_index_matches(table, cols, rename={})
    src_cols = Array(cols)
    dst_cols = src_cols.map {|c| rename[c] || c}
    exp = source.indexes(table).find {|name, specs| 
      specs[:columns] == src_cols
    }
    act = dest.indexes(table).find {|name, specs| 
      specs[:columns] == dst_cols
    }
    refute_nil act, "Expected index #{dst_cols.inspect} not found in table #{table}"
    
    match_keys = [:unique]
    exp = Wineskins::Utils.limit_hash(exp[1], match_keys)
    act = Wineskins::Utils.limit_hash(act[1], match_keys)
    assert_equal exp, act,
      "Unexpected index options for #{dst_cols.inspect} in table #{table}"
  end
  
  def assert_fk_match(table)
    match_keys = [:columns, :table, :key, :on_delete, :on_update]
    exp = source.foreign_key_list(table).map {|fk| 
            Wineskins::Utils.limit_hash(fk, match_keys) 
          }
    act = dest.foreign_key_list(table).map {|fk| 
            Wineskins::Utils.limit_hash(fk, match_keys) 
          }
    assert_equal exp.length, act.length,
      "Expected #{exp.length} foreign key constraints for table #{table}, got #{act.length}"
    exp.each do |fk|
      assert_includes act, fk, 
        "Unexpected foreign key options in table #{table}"
    end
  end
  
  def assert_fk_matches(table, cols, rename={})
    src_cols = Array(cols)
    dst_cols = src_cols.map {|c| rename[c] || c}
    exp = source.foreign_key_list(table).find {|specs| 
      specs[:columns] == src_cols
    }
    act = dest.foreign_key_list(table).find {|specs| 
      specs[:columns] == dst_cols
    }
    refute_nil act, "Expected foreign key #{dst_cols.inspect} not found in table #{table}"
    
    match_keys = [:table, :key, :on_delete, :on_update]
    exp = Wineskins::Utils.limit_hash(exp, match_keys)
    act = Wineskins::Utils.limit_hash(act, match_keys)
    assert_equal exp, act,
      "Unexpected foreign key options for #{dst_cols.inspect} in table #{table}"  
  end
  
end