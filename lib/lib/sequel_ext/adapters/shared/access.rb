# This is basically a workaround to the fact that Access provides no
# SQL access to schema data, using the ADO.OpenSchema interface.
# 
# ADO.OpenSchema attempts to give some uniformity to querying schema data for 
# different providers, but at the same time it is a clusterfuck of abstractions
# and half-baked suggestions that each provider is left to do what they can with
#
# So no attempt should be made to provide a 'generic' OpenSchema-based backend
# for the Sequel ADO provider itself; it's not possible. Thus this only is 
# intended to follow Access Jet's implementation.
#
module Sequel

  module Access
    module DatabaseMethods
    
      def schema_parse_table(table_name, opts)
        m = output_identifier_meth(opts[:dataset])
        idxs = ado_schema_indexes(table_name)
        ado_schema_columns(table_name).map {|row|
          specs = { 
            :allow_null => row.allow_null,
            :db_type => row.db_type,
            :default => row.default,
            :primary_key => !!idxs.find {|idx| 
                              idx["COLUMN_NAME"] == row["COLUMN_NAME"] &&
                              idx["PRIMARY_KEY"]
                            },
            #:ruby_default => nil,
            :type => schema_column_type(row.db_type),
            :ado_type => row["DATA_TYPE"]
          }
          specs[:default] = nil if blank_object?(specs[:default])
          [ m.call(row["COLUMN_NAME"]), specs ]
        }
      end
      
      def ado_schema_indexes(table_name)
        rows=[]
        fetch_ado_schema('indexes', [nil,nil,nil,nil,table_name]) do |row|
          rows << AdoSchema::Index.new(row)
        end
        rows
      end
      
      def ado_schema_columns(table_name)
        rows=[]
        fetch_ado_schema('columns', [nil,nil,table_name,nil]) do |row| 
          rows << AdoSchema::Column.new(row)
        end
        rows.sort!{|a,b| a["ORDINAL_POSITION"] <=> b["ORDINAL_POSITION"]}
      end
            
      def fetch_ado_schema(type, criteria=[])
        execute_open_ado_schema(type, criteria) do |s|
          cols = s.Fields.extend(Enumerable).map {|c| c.Name}
          s.getRows.transpose.each do |r|
            row = {}
            cols.each{|c| row[c] = r.shift}
            yield row
          end unless s.eof
        end
      end
            
      def execute_open_ado_schema(type, criteria=[])
        ado_schema = AdoSchema.new(type, criteria)
        synchronize(opts[:server]) do |conn|
          begin
            r = log_yield("OpenSchema #{type}, [#{criteria.join(',')}]") { 
              if ado_schema.criteria.empty?
                conn.OpenSchema(ado_schema.type) 
              else
                conn.OpenSchema(ado_schema.type, ado_schema.criteria) 
              end
            }
            yield(r) if block_given?
          rescue ::WIN32OLERuntimeError => e
            raise_error(e)
          end
        end
        nil
      end

      class AdoSchema
        
        QUERY_TYPE = {
          'columns' => 4,
          'indexes' => 12,
          'tables'  => 20
        }
        
        attr_reader :type, :criteria
        def initialize(type, crit)
          @type     = lookup_type(type)
          @criteria = ole_criteria(crit)
        end
        
        def lookup_type(type)
          return Integer(type)
        rescue
          QUERY_TYPE[type]
        end
        
        def ole_criteria(crit)
          Array(crit)
        end
        
        class Column
        
          DATA_TYPE = {
            2   => "SMALLINT",
            3   => "INTEGER",
            4   => "REAL",
            5   => "FLOAT",
            6   => "MONEY",
            7   => "DATETIME",
            11  => "BIT",
            14  => "DECIMAL",
            16  => "TINYINT",
            17  => "BYTE",
            72  => "GUID",
            128 => "BINARY",
            130 => "TEXT",
            131 => "DECIMAL",
            201 => "TEXT",
            205 => "IMAGE"
          }
          
          def initialize(row)
            @row = row
          end
          
          def [](col)
            @row[col]
          end
          
          def allow_null
            self["IS_NULLABLE"]
          end
          
          def default
            self["COLUMN_DEFAULT"]
          end
          
          def db_type
            t = DATA_TYPE[self["DATA_TYPE"]]
            if t == "DECIMAL" && precision
              t + "(#{precision.to_i},#{(scale || 0).to_i})"
            elsif t == "TEXT" && maximum_length && maximum_length > 0
              t + "(#{maximum_length.to_i})"
            else
              t
            end
          end
          
          def precision
            self["NUMERIC_PRECISION"]
          end
          
          def scale
            self["NUMERIC_SCALE"]
          end
          
          def maximum_length
            self["CHARACTER_MAXIMUM_LENGTH"]
          end
                    
        end
        
        class Index
          def initialize(row)
            @row = row
          end
          
          def [](col)
            @row[col]
          end
        end
        
      end
      
    end
  end
  
end
  