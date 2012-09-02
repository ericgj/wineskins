# Wineskins

A Ruby database transfer utility built on [Sequel](http://sequel.rubyforge.org/).

Sometimes your old wine needs to be poured into new skins too.

### A very simple case:

    Wineskins.transfer(old_db, new_db) do
      tables :students, :classes, :enrollments
    end
    
This will copy the tables, indexes, and foreign key constraints from `old_db` into `new_db`, and then insert all the records, for the three listed tables.

### To rename tables:

    Wineskins.transfer(old_db, new_db) do
      tables :students, :classes, [:enrollments, :student_classes]
    end
    
The `enrollments` table in the source will be renamed `student_classes` in the destination. All foreign keys referencing `enrollments` will be changed accordingly.

### To rename fields:

    Wineskins.transfer(old_db, new_db) do
      table :classes, :rename => {:class_id => :id}
    end
    
Primary keys, indexes, foreign keys will be changed accordingly in the destination database.

### Want to only create the schema, but not import data yet?

    tables :students, :classes, :enrollments, :schema_only => true
    
### Have the schema in place, just need to import data?

    tables :students, :classes, :enrollments, :records_only => true
    
You have finer-grained control as well:

    table :students, :create_tables => true, 
                     :create_indexes => false,
                     :create_fk_constraints => false,
                     :insert_records => true

### Adjusting column definitions

Sometimes you need to manually adjust column types or other options in the
destination. You can pass through column definitions to Sequel's schema generator, and they will be used _instead of_ the source database table:

    table :classes do
      column :slots, :integer, :null => false, :default => 25
    end
    
Note that in this example, all of the column definitions _except `slots`_ will be copied from the source table, while `slots` will be defined as specified.

### Excluding and including columns

You can also exclude specific columns entirely, or include only specified columns:

    table :enrollments, :exclude => [:final_grade, :status]
    table :students, :include => [:id, :name, :grad_year]

Although it's nearly as easy to do this manually in a hook (see below).

### Generating a transcript
    
If you just want a script for generating the schema, and actually don't want to  make database changes, do something like this:

    Wineskins.transfer(source_db, dest_db, :dryrun => true) do
      transcript 'path/to/transfer.sql'  # if not specified, writes to $stdout
      tables :schema_only => true
    end

### Manual futzing

Wineskins executes a given transfer in four stages:

  1. All the tables are created (`:create_table`)
  2. All the indexes are created via alter_table (`:create_indexes`)
  3. All the foreign key constraints are created via alter_table (`:create_fk_constraints`)
  4. The records are inserted into each table from the source database (`:insert_records`)
  
Each of these stages has a `before_*` and `after_*` hook where you can stick
whatever custom steps you need using Sequel's incredibly wide toolset, and there
are also general `before` and `after` hooks that run before and after the entire
transfer. You can define as many of these as you want at each hook. For 
instance (to turn off foreign key constraints before inserting records):

    before_insert_records do
      dest.pragma_set 'foreign_keys', 'off'
    end
    
Or to take the example above of excluding columns, you could do this manually
in a callback like:

    after_create_tables do
      dest[:enrollments].alter_table do
        drop_column :final_grade
        drop_column :status
      end
    end
    
## Motivations

This tool aims to simplify transferring data is designed around the 'canonical'
case where the destination database is completely empty, and you want to set up
everything the way it is in the source and then import the data. Of course,
many scenarios different from this are possible, but the point is that 
everything you should need to specify is either due to (1) differences from this
scenario, or (2) differences between database adapters that Sequel cannot 
handle. 

The principle is that _as much as possible, the source database should determine
the schema_, thus minimizing boilerplate code.

## Requirements

  - ruby >= 1.8.7
  - sequel ~> 3.0
  - progressbar (optional)
  
