require 'active_support/concern'

module Arql
  module Concerns
    module TableDataDefinition
      extend ActiveSupport::Concern

      class_methods do

        # Add a new +type+ column named +column_name+ to +table_name+.
        #
        # The +type+ parameter is normally one of the migrations native types,
        # which is one of the following:
        # <tt>:primary_key</tt>, <tt>:string</tt>, <tt>:text</tt>,
        # <tt>:integer</tt>, <tt>:bigint</tt>, <tt>:float</tt>, <tt>:decimal</tt>, <tt>:numeric</tt>,
        # <tt>:datetime</tt>, <tt>:time</tt>, <tt>:date</tt>,
        # <tt>:binary</tt>, <tt>:boolean</tt>.
        #
        # You may use a type not in this list as long as it is supported by your
        # database (for example, "polygon" in MySQL), but this will not be database
        # agnostic and should usually be avoided.
        #
        # Available options are (none of these exists by default):
        # * <tt>:limit</tt> -
        #   Requests a maximum column length. This is the number of characters for a <tt>:string</tt> column
        #   and number of bytes for <tt>:text</tt>, <tt>:binary</tt>, and <tt>:integer</tt> columns.
        #   This option is ignored by some backends.
        # * <tt>:default</tt> -
        #   The column's default value. Use +nil+ for +NULL+.
        # * <tt>:null</tt> -
        #   Allows or disallows +NULL+ values in the column.
        # * <tt>:precision</tt> -
        #   Specifies the precision for the <tt>:decimal</tt>, <tt>:numeric</tt>,
        #   <tt>:datetime</tt>, and <tt>:time</tt> columns.
        # * <tt>:scale</tt> -
        #   Specifies the scale for the <tt>:decimal</tt> and <tt>:numeric</tt> columns.
        # * <tt>:collation</tt> -
        #   Specifies the collation for a <tt>:string</tt> or <tt>:text</tt> column. If not specified, the
        #   column will have the same collation as the table.
        # * <tt>:comment</tt> -
        #   Specifies the comment for the column. This option is ignored by some backends.
        #
        # Note: The precision is the total number of significant digits,
        # and the scale is the number of digits that can be stored following
        # the decimal point. For example, the number 123.45 has a precision of 5
        # and a scale of 2. A decimal with a precision of 5 and a scale of 2 can
        # range from -999.99 to 999.99.
        #
        # Please be aware of different RDBMS implementations behavior with
        # <tt>:decimal</tt> columns:
        # * The SQL standard says the default scale should be 0, <tt>:scale</tt> <=
        #   <tt>:precision</tt>, and makes no comments about the requirements of
        #   <tt>:precision</tt>.
        # * MySQL: <tt>:precision</tt> [1..63], <tt>:scale</tt> [0..30].
        #   Default is (10,0).
        # * PostgreSQL: <tt>:precision</tt> [1..infinity],
        #   <tt>:scale</tt> [0..infinity]. No default.
        # * SQLite3: No restrictions on <tt>:precision</tt> and <tt>:scale</tt>,
        #   but the maximum supported <tt>:precision</tt> is 16. No default.
        # * Oracle: <tt>:precision</tt> [1..38], <tt>:scale</tt> [-84..127].
        #   Default is (38,0).
        # * DB2: <tt>:precision</tt> [1..63], <tt>:scale</tt> [0..62].
        #   Default unknown.
        # * SqlServer: <tt>:precision</tt> [1..38], <tt>:scale</tt> [0..38].
        #   Default (38,0).
        #
        # == Examples
        #
        #  User.add_column(:picture, :binary, limit: 2.megabytes)
        #  # ALTER TABLE "users" ADD "picture" blob(2097152)
        #
        #  Article.add_column(:status, :string, limit: 20, default: 'draft', null: false)
        #  # ALTER TABLE "articles" ADD "status" varchar(20) DEFAULT 'draft' NOT NULL
        #
        #  Answer.add_column(:bill_gates_money, :decimal, precision: 15, scale: 2)
        #  # ALTER TABLE "answers" ADD "bill_gates_money" decimal(15,2)
        #
        #  Measurement.add_column(:sensor_reading, :decimal, precision: 30, scale: 20)
        #  # ALTER TABLE "measurements" ADD "sensor_reading" decimal(30,20)
        #
        #  # While :scale defaults to zero on most databases, it
        #  # probably wouldn't hurt to include it.
        #  Measurement.add_column(:huge_integer, :decimal, precision: 30)
        #  # ALTER TABLE "measurements" ADD "huge_integer" decimal(30)
        #
        #  # Defines a column that stores an array of a type.
        #  User.add_column(:skills, :text, array: true)
        #  # ALTER TABLE "users" ADD "skills" text[]
        #
        #  # Defines a column with a database-specific type.
        #  Shape.add_column(:triangle, 'polygon')
        #  # ALTER TABLE "shapes" ADD "triangle" polygon
        def add_column(column_name, type, **options)
          connection.add_column(table_name, column_name, type, **options)
        end

        # Changes the column's definition according to the new options.
        # See TableDefinition#column for details of the options you can use.
        #
        #   Supplier.change_column(:name, :string, limit: 80)
        #   Post.change_column(:description, :text)
        #
        def change_column(column_name, type, options = {})
          connection.change_column(table_name, column_name, type, **options)
        end

        # Removes the column from the table definition.
        #
        #   Supplier.remove_column(:qualification)
        #
        # The +type+ and +options+ parameters will be ignored if present. It can be helpful
        # to provide these in a migration's +change+ method so it can be reverted.
        # In that case, +type+ and +options+ will be used by #add_column.
        # Indexes on the column are automatically removed.
        def remove_column(column_name, type = nil, **options)
          connection.remove_column(table_name, column_name, type, **options)
        end

        # Adds a new index to the table. +column_name+ can be a single Symbol, or
        # an Array of Symbols.
        #
        # The index will be named after the table and the column name(s), unless
        # you pass <tt>:name</tt> as an option.
        #
        # ====== Creating a simple index
        #
        #   Supplier.add_index(:name)
        #
        # generates:
        #
        #   CREATE INDEX suppliers_name_index ON suppliers(name)
        #
        # ====== Creating a unique index
        #
        #   Account.add_index([:branch_id, :party_id], unique: true)
        #
        # generates:
        #
        #   CREATE UNIQUE INDEX accounts_branch_id_party_id_index ON accounts(branch_id, party_id)
        #
        # ====== Creating a named index
        #
        #   Account.add_index([:branch_id, :party_id], unique: true, name: 'by_branch_party')
        #
        # generates:
        #
        #  CREATE UNIQUE INDEX by_branch_party ON accounts(branch_id, party_id)
        #
        # ====== Creating an index with specific key length
        #
        #   Account.add_index(:name, name: 'by_name', length: 10)
        #
        # generates:
        #
        #   CREATE INDEX by_name ON accounts(name(10))
        #
        # ====== Creating an index with specific key lengths for multiple keys
        #
        #   Account.add_index([:name, :surname], name: 'by_name_surname', length: {name: 10, surname: 15})
        #
        # generates:
        #
        #   CREATE INDEX by_name_surname ON accounts(name(10), surname(15))
        #
        # Note: SQLite doesn't support index length.
        #
        # ====== Creating an index with a sort order (desc or asc, asc is the default)
        #
        #   Account.add_index([:branch_id, :party_id, :surname], order: {branch_id: :desc, party_id: :asc})
        #
        # generates:
        #
        #   CREATE INDEX by_branch_desc_party ON accounts(branch_id DESC, party_id ASC, surname)
        #
        # Note: MySQL only supports index order from 8.0.1 onwards (earlier versions accepted the syntax but ignored it).
        #
        # ====== Creating a partial index
        #
        #   Account.add_index([:branch_id, :party_id], unique: true, where: "active")
        #
        # generates:
        #
        #   CREATE UNIQUE INDEX index_accounts_on_branch_id_and_party_id ON accounts(branch_id, party_id) WHERE active
        #
        # Note: Partial indexes are only supported for PostgreSQL and SQLite 3.8.0+.
        #
        # ====== Creating an index with a specific method
        #
        #   Developer.add_index(:name, using: 'btree')
        #
        # generates:
        #
        #   CREATE INDEX index_developers_on_name ON developers USING btree (name) -- PostgreSQL
        #   CREATE INDEX index_developers_on_name USING btree ON developers (name) -- MySQL
        #
        # Note: only supported by PostgreSQL and MySQL
        #
        # ====== Creating an index with a specific operator class
        #
        #   Developer.add_index(:name, using: 'gist', opclass: :gist_trgm_ops)
        #   # CREATE INDEX developers_on_name ON developers USING gist (name gist_trgm_ops) -- PostgreSQL
        #
        #   Developer.add_index([:name, :city], using: 'gist', opclass: { city: :gist_trgm_ops })
        #   # CREATE INDEX developers_on_name_and_city ON developers USING gist (name, city gist_trgm_ops) -- PostgreSQL
        #
        #   Developer.add_index([:name, :city], using: 'gist', opclass: :gist_trgm_ops)
        #   # CREATE INDEX developers_on_name_and_city ON developers USING gist (name gist_trgm_ops, city gist_trgm_ops) -- PostgreSQL
        #
        # Note: only supported by PostgreSQL
        #
        # ====== Creating an index with a specific type
        #
        #   Developer.add_index(:name, type: :fulltext)
        #
        # generates:
        #
        #   CREATE FULLTEXT INDEX index_developers_on_name ON developers (name) -- MySQL
        #
        # Note: only supported by MySQL.
        #
        # ====== Creating an index with a specific algorithm
        #
        #  Developer.add_index(:name, algorithm: :concurrently)
        #  # CREATE INDEX CONCURRENTLY developers_on_name on developers (name)
        #
        # Note: only supported by PostgreSQL.
        #
        # Concurrently adding an index is not supported in a transaction.
        #
        # For more information see the {"Transactional Migrations" section}[rdoc-ref:Migration].
        def add_index(column_name, options = {})
          connection.add_index(table_name, column_name, **options)
        end

        # Adds a new foreign key.
        # +to_table+ contains the referenced primary key.
        #
        # The foreign key will be named after the following pattern: <tt>fk_rails_<identifier></tt>.
        # +identifier+ is a 10 character long string which is deterministically generated from this
        # table and +column+. A custom name can be specified with the <tt>:name</tt> option.
        #
        # ====== Creating a simple foreign key
        #
        #   Article.add_foreign_key :authors
        #
        # generates:
        #
        #   ALTER TABLE "articles" ADD CONSTRAINT fk_rails_e74ce85cbc FOREIGN KEY ("author_id") REFERENCES "authors" ("id")
        #
        # ====== Creating a foreign key on a specific column
        #
        #   Article.add_foreign_key :users, column: :author_id, primary_key: "lng_id"
        #
        # generates:
        #
        #   ALTER TABLE "articles" ADD CONSTRAINT fk_rails_58ca3d3a82 FOREIGN KEY ("author_id") REFERENCES "users" ("lng_id")
        #
        # ====== Creating a cascading foreign key
        #
        #   Article.add_foreign_key :authors, on_delete: :cascade
        #
        # generates:
        #
        #   ALTER TABLE "articles" ADD CONSTRAINT fk_rails_e74ce85cbc FOREIGN KEY ("author_id") REFERENCES "authors" ("id") ON DELETE CASCADE
        #
        # The +options+ hash can include the following keys:
        # [<tt>:column</tt>]
        #   The foreign key column name on +from_table+. Defaults to <tt>to_table.singularize + "_id"</tt>
        # [<tt>:primary_key</tt>]
        #   The primary key column name on +to_table+. Defaults to +id+.
        # [<tt>:name</tt>]
        #   The constraint name. Defaults to <tt>fk_rails_<identifier></tt>.
        # [<tt>:on_delete</tt>]
        #   Action that happens <tt>ON DELETE</tt>. Valid values are +:nullify+, +:cascade+ and +:restrict+
        # [<tt>:on_update</tt>]
        #   Action that happens <tt>ON UPDATE</tt>. Valid values are +:nullify+, +:cascade+ and +:restrict+
        # [<tt>:validate</tt>]
        #   (PostgreSQL only) Specify whether or not the constraint should be validated. Defaults to +true+.
        def add_foreign_key(to_table, **options)
          connection.add_foreign_key(table_name, to_table, **options)
        end

        # Adds timestamps (+created_at+ and +updated_at+) columns to this table.
        # Additional options (like +:null+) are forwarded to #add_column.
        #
        #   Supplier.add_timestamps(null: true)
        #
        def add_timestamps(**options)
          connection.add_timestamps(table_name, **options)
        end

        # Changes the comment for a column or removes it if +nil+.
        #
        # Passing a hash containing +:from+ and +:to+ will make this change
        # reversible in migration:
        #
        #   Post.change_column_comment(:state, from: "old_comment", to: "new_comment")
        def change_column_comment(column_name, comment_or_changes)
          connection.change_column_comment(table_name, column_name, comment_or_changes)
        end

        # Sets a new default value for a column:
        #
        #   Supplier.change_column_default(:qualification, 'new')
        #   change_column_default(:accounts, :authorized, 1)
        #
        # Setting the default to +nil+ effectively drops the default:
        #
        #   User.change_column_default(:email, nil)
        #
        # Passing a hash containing +:from+ and +:to+ will make this change
        # reversible in migration:
        #
        #   Post.change_column_default(:state, from: nil, to: "draft")
        #
        def change_column_default(column_name, default_or_changes)
          connection.change_column_default(table_name, column_name, default_or_changes)
        end

        # Sets or removes a <tt>NOT NULL</tt> constraint on a column. The +null+ flag
        # indicates whether the value can be +NULL+. For example
        #
        #   User.change_column_null(:nickname, false)
        #
        # says nicknames cannot be +NULL+ (adds the constraint), whereas
        #
        #   User.change_column_null(:nickname, true)
        #
        # allows them to be +NULL+ (drops the constraint).
        #
        # The method accepts an optional fourth argument to replace existing
        # <tt>NULL</tt>s with some other value. Use that one when enabling the
        # constraint if needed, since otherwise those rows would not be valid.
        #
        # Please note the fourth argument does not set a column's default.
        def change_column_null(column_name, null, default = nil)
          connection.change_column_null(table_name, column_name, null, default)
        end

        # Renames a column.
        #
        #   Supplier.rename_column(:description, :name)
        #
        def rename_column(column_name, new_column_name)
          connection.rename_column(table_name, column_name, new_column_name)
        end

        # A block for changing columns in +table+.
        #
        #   # change_table() yields a Table instance
        #   Supplier.change_table do |t|
        #     t.column :name, :string, limit: 60
        #     # Other column alterations here
        #   end
        #
        # The +options+ hash can include the following keys:
        # [<tt>:bulk</tt>]
        #   Set this to true to make this a bulk alter query, such as
        #
        #     ALTER TABLE `users` ADD COLUMN age INT, ADD COLUMN birthdate DATETIME ...
        #
        #   Defaults to false.
        #
        #   Only supported on the MySQL and PostgreSQL adapter, ignored elsewhere.
        #
        # ====== Add a column
        #
        #   Supplier.change_table do |t|
        #     t.column :name, :string, limit: 60
        #   end
        #
        # ====== Add 2 integer columns
        #
        #   Supplier.change_table do |t|
        #     t.integer :width, :height, null: false, default: 0
        #   end
        #
        # ====== Add created_at/updated_at columns
        #
        #   Supplier.change_table do |t|
        #     t.timestamps
        #   end
        #
        # ====== Add a foreign key column
        #
        #   Supplier.change_table do |t|
        #     t.references :company
        #   end
        #
        # Creates a <tt>company_id(bigint)</tt> column.
        #
        # ====== Add a polymorphic foreign key column
        #
        #  Supplier.change_table do |t|
        #    t.belongs_to :company, polymorphic: true
        #  end
        #
        # Creates <tt>company_type(varchar)</tt> and <tt>company_id(bigint)</tt> columns.
        #
        # ====== Remove a column
        #
        #  Supplier.change_table do |t|
        #    t.remove :company
        #  end
        #
        # ====== Remove several columns
        #
        #  Supplier.change_table do |t|
        #    t.remove :company_id
        #    t.remove :width, :height
        #  end
        #
        # ====== Remove an index
        #
        #  Supplier.change_table do |t|
        #    t.remove_index :company_id
        #  end
        #
        # See also Table for details on all of the various column transformations.
        def change_table(**options)
          connection.change_table(table_name, **options)
        end

        # Renames a table.
        #
        #   rename_table('octopi')
        #
        def rename_table(new_name)
          connection.rename_table(table_name, new_name)
        end

        # Changes the comment for a table or removes it if +nil+.
        #
        # Passing a hash containing +:from+ and +:to+ will make this change
        # reversible in migration:
        #
        #   Post.change_table_comment(from: "old_comment", to: "new_comment")
        def change_table_comment(comment_or_changes)
          connection.change_table_comment(table_name, comment_or_changes)
        end

        # Drops a table from the database.
        #
        # [<tt>:force</tt>]
        #   Set to +:cascade+ to drop dependent objects as well.
        #   Defaults to false.
        # [<tt>:if_exists</tt>]
        #   Set to +true+ to only drop the table if it exists.
        #   Defaults to false.
        #
        # Although this command ignores most +options+ and the block if one is given,
        # it can be helpful to provide these in a migration's +change+ method so it can be reverted.
        # In that case, +options+ and the block will be used by #create_table.
        def drop_table(**options)
          connection.drop_table(table_name, **options)
        end

        # Returns an array of foreign keys for the given table.
        # The foreign keys are represented as ForeignKeyDefinition objects.
        def foreign_keys
          connection.foreign_keys(table_name)
        end

        # Removes the given foreign key from the table. Any option parameters provided
        # will be used to re-add the foreign key in case of a migration rollback.
        # It is recommended that you provide any options used when creating the foreign
        # key so that the migration can be reverted properly.
        #
        # Removes the foreign key on +accounts.branch_id+.
        #
        #   Account.remove_foreign_key :branches
        #
        # Removes the foreign key on +accounts.owner_id+.
        #
        #   Account.remove_foreign_key column: :owner_id
        #
        # Removes the foreign key on +accounts.owner_id+.
        #
        #   Account.remove_foreign_key to_table: :owners
        #
        # Removes the foreign key named +special_fk_name+ on the +accounts+ table.
        #
        #   Account.remove_foreign_key name: :special_fk_name
        #
        # The +options+ hash accepts the same keys as SchemaStatements#add_foreign_key
        # with an addition of
        # [<tt>:to_table</tt>]
        #   The name of the table that contains the referenced primary key.
        def remove_foreign_key(to_table = nil, **options)
          connection.remove_foreign_key(table_name, to_table, **options)
        end

        # Removes the given index from the table.
        #
        # Removes the index on +branch_id+ in the +accounts+ table if exactly one such index exists.
        #
        #   Account.remove_index :branch_id
        #
        # Removes the index on +branch_id+ in the +accounts+ table if exactly one such index exists.
        #
        #   Account.remove_index column: :branch_id
        #
        # Removes the index on +branch_id+ and +party_id+ in the +accounts+ table if exactly one such index exists.
        #
        #   Account.remove_index column: [:branch_id, :party_id]
        #
        # Removes the index named +by_branch_party+ in the +accounts+ table.
        #
        #   Account.remove_index name: :by_branch_party
        #
        # Removes the index named +by_branch_party+ in the +accounts+ table +concurrently+.
        #
        #   Account.remove_index name: :by_branch_party, algorithm: :concurrently
        #
        # Note: only supported by PostgreSQL.
        #
        # Concurrently removing an index is not supported in a transaction.
        #
        # For more information see the {"Transactional Migrations" section}[rdoc-ref:Migration].
        def remove_index(options = {})
          connection.remove_index(table_name, **options)
        end

        # Removes the timestamp columns (+created_at+ and +updated_at+) from the table definition.
        #
        #  Supplier.remove_timestamps
        #
        def remove_timestamps(**options)
          connection.remove_timestamps(**options)
        end

        # Renames an index.
        #
        # Rename the +index_people_on_last_name+ index to +index_users_on_last_name+:
        #
        #   Person.rename_index 'index_people_on_last_name', 'index_users_on_last_name'
        #
        def rename_index(old_name, new_name)
          connection.rename_index(table_name, old_name, new_name)
        end

        # Returns the table comment that's stored in database metadata.
        def table_comment
          connection.table_comment(table_name)
        end

      end
    end
  end
end
