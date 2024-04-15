require 'active_support/concern'

module Arql
  module Concerns
    module GlobalDataDefinition
      extend ActiveSupport::Concern

      included do

        # Example:
        #
        #   create_table :post, id: false, primary_key: :id do |t|
        #     t.column :id, :bigint, precison: 19, comment: 'ID'
        #     t.column :name, :string, comment: '名称'
        #     t.column :gmt_created, :datetime, comment: '创建时间'
        #     t.column :gmt_modified, :datetime, comment: '最后修改时间'
        #   end
        #
        # Creates a new table with the name +table_name+. +table_name+ may either
        # be a String or a Symbol.
        #
        # There are two ways to work with #create_table. You can use the block
        # form or the regular form, like this:
        #
        # === Block form
        #
        #   # create_table() passes a TableDefinition object to the block.
        #   # This form will not only create the table, but also columns for the
        #   # table.
        #
        #   create_table(:suppliers) do |t|
        #     t.column :name, :string, limit: 60
        #     # Other fields here
        #   end
        #
        # === Block form, with shorthand
        #
        #   # You can also use the column types as method calls, rather than calling the column method.
        #   create_table(:suppliers) do |t|
        #     t.string :name, limit: 60
        #     # Other fields here
        #   end
        #
        # === Regular form
        #
        #   # Creates a table called 'suppliers' with no columns.
        #   create_table(:suppliers)
        #   # Add a column to 'suppliers'.
        #   add_column(:suppliers, :name, :string, {limit: 60})
        #
        # The +options+ hash can include the following keys:
        # [<tt>:id</tt>]
        #   Whether to automatically add a primary key column. Defaults to true.
        #   Join tables for {ActiveRecord::Base.has_and_belongs_to_many}[rdoc-ref:Associations::ClassMethods#has_and_belongs_to_many] should set it to false.
        #
        #   A Symbol can be used to specify the type of the generated primary key column.
        # [<tt>:primary_key</tt>]
        #   The name of the primary key, if one is to be added automatically.
        #   Defaults to +id+. If <tt>:id</tt> is false, then this option is ignored.
        #
        #   If an array is passed, a composite primary key will be created.
        #
        #   Note that Active Record models will automatically detect their
        #   primary key. This can be avoided by using
        #   {self.primary_key=}[rdoc-ref:AttributeMethods::PrimaryKey::ClassMethods#primary_key=] on the model
        #   to define the key explicitly.
        #
        # [<tt>:options</tt>]
        #   Any extra options you want appended to the table definition.
        # [<tt>:temporary</tt>]
        #   Make a temporary table.
        # [<tt>:force</tt>]
        #   Set to true to drop the table before creating it.
        #   Set to +:cascade+ to drop dependent objects as well.
        #   Defaults to false.
        # [<tt>:if_not_exists</tt>]
        #   Set to true to avoid raising an error when the table already exists.
        #   Defaults to false.
        # [<tt>:as</tt>]
        #   SQL to use to generate the table. When this option is used, the block is
        #   ignored, as are the <tt>:id</tt> and <tt>:primary_key</tt> options.
        #
        # ====== Add a backend specific option to the generated SQL (MySQL)
        #
        #   create_table(:suppliers, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4')
        #
        # generates:
        #
        #   CREATE TABLE suppliers (
        #     id bigint auto_increment PRIMARY KEY
        #   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        #
        # ====== Rename the primary key column
        #
        #   create_table(:objects, primary_key: 'guid') do |t|
        #     t.column :name, :string, limit: 80
        #   end
        #
        # generates:
        #
        #   CREATE TABLE objects (
        #     guid bigint auto_increment PRIMARY KEY,
        #     name varchar(80)
        #   )
        #
        # ====== Change the primary key column type
        #
        #   create_table(:tags, id: :string) do |t|
        #     t.column :label, :string
        #   end
        #
        # generates:
        #
        #   CREATE TABLE tags (
        #     id varchar PRIMARY KEY,
        #     label varchar
        #   )
        #
        # ====== Create a composite primary key
        #
        #   create_table(:orders, primary_key: [:product_id, :client_id]) do |t|
        #     t.belongs_to :product
        #     t.belongs_to :client
        #   end
        #
        # generates:
        #
        #   CREATE TABLE order (
        #       product_id bigint NOT NULL,
        #       client_id bigint NOT NULL
        #   );
        #
        #   ALTER TABLE ONLY "orders"
        #     ADD CONSTRAINT orders_pkey PRIMARY KEY (product_id, client_id);
        #
        # ====== Do not add a primary key column
        #
        #   create_table(:categories_suppliers, id: false) do |t|
        #     t.column :category_id, :bigint
        #     t.column :supplier_id, :bigint
        #   end
        #
        # generates:
        #
        #   CREATE TABLE categories_suppliers (
        #     category_id bigint,
        #     supplier_id bigint
        #   )
        #
        # ====== Create a temporary table based on a query
        #
        #   create_table(:long_query, temporary: true,
        #     as: "SELECT * FROM orders INNER JOIN line_items ON order_id=orders.id")
        #
        # generates:
        #
        #   CREATE TEMPORARY TABLE long_query AS
        #     SELECT * FROM orders INNER JOIN line_items ON order_id=orders.id
        #
        # See also TableDefinition#column for details on how to create columns.
        def create_table(table_name, **options, &blk)
          env_name = options[:env]
          unless env_name
            raise ArgumentError, ':env option is required' if Arql::App.instance.environments.size > 1

            env_name = Arql::App.instance.environments.first
          end
          options = options.except(:env)
          Arql::App.instance.definitions[env_name].connection.create_table(table_name, **options, &blk)
        end

        # Creates a new join table with the name created using the lexical order of the first two
        # arguments. These arguments can be a String or a Symbol.
        #
        #   # Creates a table called 'assemblies_parts' with no id.
        #   create_join_table(:assemblies, :parts)
        #
        # You can pass an +options+ hash which can include the following keys:
        # [<tt>:table_name</tt>]
        #   Sets the table name, overriding the default.
        # [<tt>:column_options</tt>]
        #   Any extra options you want appended to the columns definition.
        # [<tt>:options</tt>]
        #   Any extra options you want appended to the table definition.
        # [<tt>:temporary</tt>]
        #   Make a temporary table.
        # [<tt>:force</tt>]
        #   Set to true to drop the table before creating it.
        #   Defaults to false.
        #
        # Note that #create_join_table does not create any indices by default; you can use
        # its block form to do so yourself:
        #
        #   create_join_table :products, :categories do |t|
        #     t.index :product_id
        #     t.index :category_id
        #   end
        #
        # ====== Add a backend specific option to the generated SQL (MySQL)
        #
        #   create_join_table(:assemblies, :parts, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8')
        #
        # generates:
        #
        #   CREATE TABLE assemblies_parts (
        #     assembly_id bigint NOT NULL,
        #     part_id bigint NOT NULL,
        #   ) ENGINE=InnoDB DEFAULT CHARSET=utf8
        #
        def create_join_table(table_1, table_2, column_options: {}, **options)
          env_name = options[:env]
          unless env_name
            raise ArgumentError, ':env option is required' if Arql::App.instance.environments.size > 1

            env_name = Arql::App.instance.environments.first
          end
          options = options.except(:env)
          Arql::App.instance.definitions[env_name].connection.create_join_table(table_1, table_2, column_options, **options)
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
        def drop_table(table_name, **options)
          env_name = options[:env]
          unless env_name
            raise ArgumentError, ':env option is required' if Arql::App.instance.environments.size > 1

            env_name = Arql::App.instance.environments.first
          end
          options = options.except(:env)
          Arql::App.instance.definitions[env_name].connection.drop_table(table_name, **options)
        end

        # Drops the join table specified by the given arguments.
        # See #create_join_table for details.
        #
        # Although this command ignores the block if one is given, it can be helpful
        # to provide one in a migration's +change+ method so it can be reverted.
        # In that case, the block will be used by #create_join_table.
        def drop_join_table(table_1, table_2, **options)
          env_name = options[:env]
          unless env_name
            raise ArgumentError, ':env option is required' if Arql::App.instance.environments.size > 1

            env_name = Arql::App.instance.environments.first
          end
          options = options.except(:env)
          Arql::App.instance.definitions[env_name].connection.drop_join_table(table_1, table_2, **options)
        end

        # Renames a table.
        #
        #   rename_table('octopuses', 'octopi')
        #
        def rename_table(table_name, new_name)
          env_name = options[:env]
          unless env_name
            raise ArgumentError, ':env option is required' if Arql::App.instance.environments.size > 1

            env_name = Arql::App.instance.environments.first
          end
          options = options.except(:env)
          Arql::App.instance.definitions[env_name].connection.rename_table(table_name, new_name)
        end
      end
    end
  end
end
