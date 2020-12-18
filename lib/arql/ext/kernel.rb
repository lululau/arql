module Kernel
  CSV_BOM = "\xef\xbb\xbf"

  def sql(sql)
    ActiveRecord::Base.connection.exec_query(sql)
  end

  def print_tables(format = :md)
    require 'terminal-table'

    tables = ActiveRecord::Base.connection.tables.map do |table_name|
      {
        table: table_name,
        table_comment: ActiveRecord::Base.connection.table_comment(table_name) || '',
        columns: ::ActiveRecord::Base.connection.columns(table_name)
      }
    end

    outputs = tables.map do |table|
      table_name = table[:table]
      table_comment = table[:table_comment]
      case format
      when :md
        "# #{table_name} #{table_comment}\n\n" +
          Terminal::Table.new { |t|
          t.headings = ['PK', 'Name', 'SQL Type', 'Limit', 'Precision', 'Scale', 'Default', 'Nullable', 'Comment']
          t.rows = table[:columns].map { |column|
            pk = if [::ActiveRecord::Base.connection.primary_key(table_name)].flatten.include?(column_name)
                   'Y'
                 else
                   ''
                 end
            [pk, "`#{column.name}`", column.sql_type, column.sql_type_metadata.limit || '', column.sql_type_metadata.precision || '',
             column.sql_type_metadata.scale || '', column.default || '', column.null, column.comment || '']
          }
          t.style = {
            border_top: false,
            border_bottom: false,
            border_i: '|'
          }
        }.to_s.lines.map { |l| '  ' + l }.join
      when :org
        "* #{table_name} #{table_comment}\n\n" +
          Terminal::Table.new { |t|
          t.headings = ['PK', 'Name', 'SQL Type', 'Limit', 'Precision', 'Scale', 'Default', 'Nullable', 'Comment']
          t.rows = table[:columns].map { |column|
            pk = if [::ActiveRecord::Base.connection.primary_key(table_name)].flatten.include?(column_name)
                   'Y'
                 else
                   ''
                 end
            [pk, "=#{column.name}=", column.sql_type, column.sql_type_metadata.limit || '', column.sql_type_metadata.precision || '',
             column.sql_type_metadata.scale || '', column.default || '', column.null, column.comment || '']
          }
          t.style = {
            border_top: false,
            border_bottom: false,
          }
        }.to_s.lines.map { |l| '  ' + l.gsub(/^\+|\+$/, '|') }.join
      when :sql
        "-- Table: #{table_name}\n\n" + ActiveRecord::Base.connection.exec_query("show create table `#{table_name}`").rows.last.last + ';'
      end
    end

    outputs.each { |out| puts out; puts }
  end

  def generate_csv(filename, **options, &block)
    opts = {
      col_sep: "\t",
      row_sep: "\r\n"
    }
    opts.merge!(options.except(:encoding))
    encoding = options[:encoding] || 'UTF-16LE'
    File.open(File.expand_path(filename), "w:#{encoding}") do |file|
      file.write(CSV_BOM)
      file.write CSV.generate(**opts, &block)
    end
  end

  def parse_csv(filename, **options)
    encoding = options[:encoding] || 'UTF-16'
    opts = {
      headers: false,
      col_sep: "\t",
      row_sep: "\r\n"
    }
    opts.merge!(options.except(:encoding))
    CSV.parse(IO.read(File.expand_path(filename), encoding: encoding, binmode: true).encode('UTF-8'), **opts).to_a
  end

  def generate_excel(filename)
    Axlsx::Package.new do |package|
      yield(package.workbook)
      package.serialize(filename)
    end
  end

  def parse_excel(filename)
    xlsx = Roo::Excelx.new(File.expand_path(filename))
    xlsx.sheets.each_with_object({}) do |sheet_name, result|
      begin
        result[sheet_name] = xlsx.sheet(sheet_name).to_a
      rescue
      end
    end
  end

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
    ActiveRecord::Base.connection.create_table(table_name, **options, &blk)
  end
end
