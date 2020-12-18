module Arql
  module Extension
    extend ActiveSupport::Concern

    def t
      puts Terminal::Table.new { |t|
        v.each { |row| t << (row || :separator) }
      }
    end

    def v
      t = []
      t << ['Attribute Name', 'Attribute Value', 'SQL Type', 'Comment']
      t << nil
      self.class.connection.columns(self.class.table_name).each do |column|
        t << [column.name, read_attribute(column.name), column.sql_type, column.comment || '']
      end
      t
    end

    def to_insert_sql
      self.class.to_insert_sql([self])
    end

    def to_upsert_sql
      self.class.to_upsert_sql([self])
    end

    def write_csv(filename, *fields, **options)
      [self].write_csv(filename, *fields, **options)
    end

    def write_excel(filename, *fields, **options)
      [self].write_excel(filename, *fields, **options)
    end

    included do
    end

    class_methods do
      def t
        table_name = Commands::Table::get_table_name(name)
        puts "\nTable: #{table_name}"
        puts Commands::Table::table_info_table(table_name)
      end

      def v
        table_name = Commands::Table::get_table_name(name)
        Commands::Table::table_info(table_name)
      end
      def to_insert_sql(records, batch_size=1)
        to_sql(records, :skip, batch_size)
      end

      def to_upsert_sql(records, batch_size=1)
        to_sql(records, :update, batch_size)
      end

      def to_sql(records, on_duplicate, batch_size)
        records.in_groups_of(batch_size, false).map do |group|
          ActiveRecord::InsertAll.new(self, group.map(&:attributes), on_duplicate: on_duplicate).send(:to_sql) + ';'
        end.join("\n")
      end

      def to_create_sql
        ActiveRecord::Base.connection.exec_query("show create table #{table_name}").rows.last.last
      end
    end
  end

  class Definition
    class << self
      def models
        @@models ||= []
      end

      def redefine
        options = @@options
        @@models.each do |model|
          Object.send :remove_const, model[:model].name.to_sym if model[:model]
          Object.send :remove_const, model[:abbr].to_sym if model[:abbr]
        end
        @@models = []
        ActiveRecord::Base.connection.tap do |conn|
          conn.tables.each do |table_name|
            table_comment = conn.table_comment(table_name)
            conn.primary_key(table_name).tap do |pkey|
              table_name.camelize.tap do |const_name|
                const_name = 'Modul' if const_name == 'Module'
                const_name = 'Clazz' if const_name == 'Class'
                Class.new(::ArqlModel) do
                  include Arql::Extension
                  if pkey.is_a?(Array)
                    self.primary_keys = pkey
                  else
                    self.primary_key = pkey
                  end
                  self.table_name = table_name
                  self.inheritance_column = nil
                  self.default_timezone = :local
                  if options[:created_at].present?
                    define_singleton_method :timestamp_attributes_for_create do
                      options[:created_at]
                    end
                  end

                  if options[:updated_at].present?
                    define_singleton_method :timestamp_attributes_for_update do
                      options[:updated_at]
                    end
                  end
                end.tap do |clazz|
                  Object.const_set(const_name, clazz).tap do |const|
                    const_name.gsub(/[a-z]*/, '').tap do |bare_abbr|
                      abbr_const = nil
                      9.times do |idx|
                        abbr = idx.zero? ? bare_abbr : "#{bare_abbr}#{idx+1}"
                        unless Object.const_defined?(abbr)
                          Object.const_set abbr, const
                          abbr_const = abbr
                          break
                        end
                      end

                      @@models << {
                        model: const,
                        abbr: abbr_const,
                        table: table_name,
                        comment: table_comment
                      }
                    end
                  end
                end
              end
            end
          end
        end

        App.instance&.load_initializer!
      end
    end

    def initialize(options)
      @@options = options
      @@models = []
      ActiveRecord::Base.connection.tap do |conn|
        Object.const_set('ArqlModel', Class.new(ActiveRecord::Base) do
                           self.abstract_class = true

                           define_singleton_method(:indexes) do
                             conn.indexes(table_name).map do |idx|
                               {
                                 Table: idx.table,
                                 Name: idx.name,
                                 Columns: idx.columns.join(', '),
                                 Unique: idx.unique,
                                 Comment: idx.comment
                               }
                             end.t
                           end
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
                           define_singleton_method(:add_column) do |column_name, type, **options|
                             conn.add_column(table_name, column_name, type, **options)
                           end

                           # Changes the column's definition according to the new options.
                           # See TableDefinition#column for details of the options you can use.
                           #
                           #   Supplier.change_column(:name, :string, limit: 80)
                           #   Post.change_column(:description, :text)
                           #
                           define_singleton_method(:change_column) do |column_name, type, options = {}|
                             conn.change_column(table_name, column_name, type, options)
                           end

                           # Removes the column from the table definition.
                           #
                           #   Supplier.remove_column(:qualification)
                           #
                           # The +type+ and +options+ parameters will be ignored if present. It can be helpful
                           # to provide these in a migration's +change+ method so it can be reverted.
                           # In that case, +type+ and +options+ will be used by #add_column.
                           # Indexes on the column are automatically removed.
                           define_singleton_method(:remove_column) do |column_name, type = nil, **options|
                             conn.remove_column(table_name, column_name, type, **options)
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
                           define_singleton_method(:add_index) do |column_name, options = {}|
                             conn.add_index(table_name, column_name, options)
                           end
                         end)
        conn.tables.each do |table_name|
          table_comment = conn.table_comment(table_name)
          conn.primary_key(table_name).tap do |pkey|
            table_name.camelize.tap do |const_name|
              const_name = 'Modul' if const_name == 'Module'
              const_name = 'Clazz' if const_name == 'Class'
              Class.new(::ArqlModel) do
                include Arql::Extension
                if pkey.is_a?(Array)
                  self.primary_keys = pkey
                else
                  self.primary_key = pkey
                end
                self.table_name = table_name
                self.inheritance_column = nil
                self.default_timezone = :local
                if options[:created_at].present?
                  define_singleton_method :timestamp_attributes_for_create do
                    options[:created_at]
                  end
                end

                if options[:updated_at].present?
                  define_singleton_method :timestamp_attributes_for_update do
                    options[:updated_at]
                  end
                end
              end.tap do |clazz|
                Object.const_set(const_name, clazz).tap do |const|
                  const_name.gsub(/[a-z]*/, '').tap do |bare_abbr|
                    abbr_const = nil
                    9.times do |idx|
                      abbr = idx.zero? ? bare_abbr : "#{bare_abbr}#{idx+1}"
                      unless Object.const_defined?(abbr)
                        Object.const_set abbr, const
                        abbr_const = abbr
                        break
                      end
                    end

                    @@models << {
                      model: const,
                      abbr: abbr_const,
                      table: table_name,
                      comment: table_comment
                    }
                  end
                end
              end
            end
          end
        end
      end
    end

    ::ActiveRecord::Relation.class_eval do
      def t(*attrs, **options)
        records.t(*attrs, **options)
      end

      def v
        records.v
      end

      def a
        to_a
      end

      def write_csv(filename, *fields, **options)
        records.write_csv(filename, *fields, **options)
      end

      def write_excel(filename, *fields, **options)
        records.write_excel(filename, *fields, **options)
      end

    end
  end
end
