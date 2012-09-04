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

(_Note: not yet implemented._)
You can also exclude specific columns entirely, or include only specified columns:

    table :enrollments, :exclude => [:final_grade, :status]
    table :students, :include => [:id, :name, :grad_year]

Although it's nearly as easy to do this manually in a hook (see below).

### Limiting the imported data

(_Note: not yet implemented._)
It's also possible to specify a filter on the source records that get imported.

    table :students do
      insert_records :grad_year => (2010..2012)
    end

Filters can be anything that Sequel accepts as arguments to `Dataset#filter`.

### Generating a transcript
    
If you just want a script for generating the schema later, and don't actually
want to make database changes, do something like this:

    Wineskins.transfer(source_db, dest_db, :dryrun => true) do
      transcript 'path/to/transfer.sql'  # if no arg, writes to $stdout
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
    
### A note on the syntax

In the examples above I've used both a 'hash-options' style and a block syntax.
Either can be used interchangably and even in combination if you want (although
it's ugly looking). The options set in the block always override the options
hash. Also, custom `column` definitions must be done within a block.

## Motivations

This tool aims to simplify transferring data is designed around the canonical
case where the destination database is completely empty, and you want to set up
everything the way it is in the source and then import the data. Of course,
many scenarios different from this are possible, but the point is that 
everything you should need to specify is either due to (1) differences from this
scenario, or (2) differences between database adapters that Sequel cannot 
handle. 

The principle is that _as much as possible, the source database should determine
the schema_, thus minimizing boilerplate schema definition code. Also it greatly
avoids, for simple but typical cases, the great pain and knashing of the teeth 
involved in transforming the source data for import.

## Please help

This is a young young project, don't expect it will work out of the box without
some futzing. It's only been formally tested on Sqlite to Sqlite transfers, and
ad-hoc tested on a 'real' MS Access to Sqlite transfer. (In fact you'll see 
there's some patches to the Sequel ADO/Access adapter in there, these hopefully
will be moved into Sequel proper eventually.)

What I'm saying is, if you start using it and run into weird shit, at the very 
least let me know about it. Better still if you send some informed guesses as to
what's going on. Pull requests are awesome and going the extra mile and all that
... but before you go to the trouble, unless it's a really minor fix, let me 
know about the issue, I might be able to save you some time and we can have
a conversation about it you know?

There's a TODO list in the project root if you want to see where I'm thinking 
of heading, comments welcome.


## Requirements

  - ruby >= 1.8.7
  - sequel ~> 3.0
  - progressbar (optional)
  
