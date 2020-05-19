# Arql

  Arql is a simple utility gem which combines Rails ActiveRecord and Pry together, with additional helpful Pry commands. It defines model clases automatically from DB table informations.
  You can use this utility as your SQL editor and querier if you are a Ruby guy.

## Installation

Execute:

    $ gem install arql

If system permission problems occurs, try with sudo:

    $ sudo gem install arql

## Usage

### Command line options

```
Usage: arql [options] [ruby file]

  If neither [ruby file] nor -e option specified, and STDIN is not a tty, a Pry REPL will be launched,
  otherwise the specified ruby file or -e option value or ruby code read from STDIN will be run, and no REPL launched

    -c, --conf=CONFIG_FILE           Specify config file, default is $HOME/.arql.yml, or $HOME/.arql.d/init.yml.
    -i, --initializer=INITIALIZER    Specify initializer ruby file, default is $HOME/.arql.rb, or $HOME/.arql.d/init.rb.
    -e, --env=ENVIRON                Specify config environment.
    -a, --db-adapter=DB_ADAPTER      Specify database Adapter, default is mysql2
    -h, --db-host=DB_HOST            Specify database host
    -p, --db-port=DB_PORT            Specify database port
    -d, --db-name=DB_NAME            Specify database name
    -u, --db-user=DB_USER            Specify database user
    -P, --db-password=DB_PASSWORD    Specify database password
    -n, --db-encoding=DB_ENCODING    Specify database encoding, default is utf8
    -o, --db-pool=DB_POOL            Specify database pool size, default is 5
    -H, --ssh-host=SSH_HOST          Specify SSH host
    -O, --ssh-port=SSH_PORT          Specify SSH port
    -U, --ssh-user=SSH_USER          Specify SSH user
    -W, --ssh-password=SSH_PASSWORD  Specify SSH password
    -LSSH_LOCAL_PORT,                Specify local SSH proxy port
        --ssh-local-port
    -E, --eval=CODE                  evaluate CODE
    -S, --show-sql                   Show SQL on STDOUT
    -w, --write-sql=OUTPUT           Write SQL to OUTPUT file
    -A, --append-sql=OUTPUT          Append SQL to OUTPUT file
        --help
                                     Prints this help
```

#### -c, --config=CONFIG_FILE

Specify location of config file, default is `$HOME/.arql.yml`, or `$HOME/.arql.d/init.yml`.

The config file typically is as same as a Rails database config file, but with several additional config options, e.g. `ssh` options, etc.

See `Config File` section.

#### -i, --initializer=INITIALIZER

Specify a Ruby source file to be evaluated after ActiveRecord models are defined, default is  `$HOME/.arql.rb`, or `$HOME/.arql.d/init.rb` if exists.

#### -e, --env=ENVIRON

Specify an environment name which should be defined in config file.

#### -E, --eval=CODE

Specify a Ruby code fragment to be evaluated, if this option was specified, no Pry REPL will be launched.

#### -S, --show-sql

arql does not show SQL log by default, use this option to turn it on.

#### -w, --write-sql=OUTPUT

You can also let arql write SQL logs into a file use this option.

#### -A, --append-sql-OUTOUT

Like `-w`, but without file content truncation.

#### DB options

Options described in this section typically should be configured in the config file, these options are just shortcuts of
the corresponding configurations in case of that you want modify some configuration items on CLI directly.

#####  -a, --db-adapter=DB_ADAPTER

Specify DB adapter, available values: 

+ `mysql2`
+ `postgresql`
+ `sqlite3`
+ `sqlserver`
+ `oracle_enhanced`

#####  -h, --db-host=DB_HOST

Specify DB host

#####  -p, --db-port=DB_PORT

Specify DB port

#####  -d, --db-name=DB_NAME

Specify DB name

#####  -u, --db-user=DB_USER

Specify DB username

#####  -P, --db-password=DB_PASSWORD

Specify DB password

#####  -n, --db-encoding=DB_ENCODING

Specify DB character encoding, default is `utf8`

#####  -o, --db-pool=DB_POOL

Specify size of DB connection pool, default is `5`

#####  -H, --ssh-host=SSH_HOST

Specify ssh host for ssh proxy

#####  -O, --ssh-port=SSH_PORT

Specify ssh port for ssh proxy

#####  -U, --ssh-user=SSH_USER

Specify ssh username for ssh proxy

#####  -W, --ssh-password=SSH_PASSWORD

Specify ssh password for ssh proxy

#####  -LSSH_LOCAL_PORT

Specify local port for ssh proxy, default is a _random_ port

### Config file

The config file typically is as same as a Rails database config file, but with several additional config options.

#### Additional configurations

1. `created_at`: An array contains customized column names for the ActiveRecord `created_at` field, default value is `created_at`, value of the column will be filled with current time stamp when created if specified
2. `updated_at`: An array contains customized column names for the ActiveRecord `updated_at` field, default value is `updated_at`, value of the column will be filled with current time stamp when updated if specified
3. `ssh.host`: host of ssh proxy
4. `ssh.port`: port of ssh proxy
5. `ssh.user`: username of ssh proxy
6. `ssh.password`: password of ssh proxy
7. `ssh.local_port`: local port of ssh proxy

#### Config Example

```
default: &default
  adapter: mysql2
  encoding: utf8
  created_at: ["gmt_created"]
  updated_at: ["gmt_modified"]

local:
  <<: *default
  username: root
  database: blog
  password:
  socket: /tmp/mysql.sock

dev:
  <<: *default
  host: devdb.mycompany.com
  port: 3306
  username: root
  password: 123456
  database: blog
  ssh:
    host: dev.mycompany.com
    port: 22
    user: deploy
    password: 12345678
    local_port: 3307
```

### Use as a REPL

If neither [ruby file] nor -e option specified, and STDIN is not a tty, a Pry REPL will be launched with pry-byebug loaded.

Arql provides some Pry commands:

#### info

The `info` command prints current DB connection information and SSH proxy information, e.g.:

```
Database Connection Information:
    Host:
    Port:
    Username:  root
    Password:
    Database:  test
    Adapter:   mysql2
    Encoding:  utf8
    Pool Size: 5
```

#### m

The `m` command print all table names with corresponding model class, and abbr class names, e.g.:

```
+-----------------|----------------|------+
| Table Name      | Model Class    | Abbr |
+-----------------|----------------|------+
| all_songs       | AllSongs       | AS   |
| datetypes       | Datetypes      | D    |
| hello           | Hello          | H    |
| permission      | Permission     | P    |
| permission_role | PermissionRole | PR   |
| person          | Person         |      |
| role            | Role           | R    |
| role_user       | RoleUser       | RU   |
| test            | Test           | T    |
| user            | User           | U    |
+-----------------|----------------|------+
```

The `m` command has an alias: `l`

#### t

Given a table name or model class, the `t` command prints the table's definition information.

```
Table: person
+----|------------|------------------|-----------|-------|-----------|-------|---------|----------|---------+
| PK | Name       | SQL Type         | Ruby Type | Limit | Precision | Scale | Default | Nullable | Comment |
+----|------------|------------------|-----------|-------|-----------|-------|---------|----------|---------+
| Y  | id         | int(11) unsigned | integer   | 4     |           |       |         | false    |         |
|    | name       | varchar(64)      | string    | 64    |           |       |         | true     |         |
|    | age        | int(11)          | integer   | 4     |           |       |         | true     |         |
|    | gender     | int(4)           | integer   | 4     |           |       |         | true     |         |
|    | grade      | int(4)           | integer   | 4     |           |       |         | true     |         |
|    | blood_type | varchar(4)       | string    | 4     |           |       |         | true     |         |
+----|------------|------------------|-----------|-------|-----------|-------|---------|----------|---------+
```

#### show-sql / hide-sql

This pair of commands toggle display of SQL logs in Pry REPL.

#### reconnect

The `reconnect` command just simply reconnects current DB connection.

#### redefine

The `redefine` command redefines ActiveRecord model classes from DB tables informations.

### Use as code interpreter

If a ruby file is specified as command line argument, or the `-e` option is specified, or STDIN is a tty, then no Pry
REPL will be launched, instead, it evaluates the file or code fragment specified, just after model class definition is
done. You can think this usage as the `runner` sub-command of `rails` command.

### Additional extension methods

#### to_insert_sql / to_upsert_sql

You can call `to_insert_sql` / `to_upsert_sql` on any ActiveRecord model instance to get a insert or upsert SQL of the object.

These tow methods are also available on any array object which contains only ActiveRecord model instance objects.

```
ARQL ❯ Person.all.to_a.to_insert_sql
=> "INSERT INTO `person` (`id`,`name`,`age`,`gender`,`grade`,`blood_type`) VALUES (1, 'Jack', 30, NULL, NULL, NULL), (2, 'Jack', 11, 1, NULL, NULL), (3, 'Jack', 12, 1, NULL, NULL), (4, 'Jack', 30, 1, NULL, NULL), (5, 'Jack', 12, 2, NULL, NULL), (6, 'Jack', 2, 2, 2, NULL), (7, 'Jack', 3, 2, 2, NULL), (8, 'Jack', 30, 2, 2, 'AB'), (9, 'Jack', 30, 2, 2, 'AB'), (10, 'Jack', 30, 2, 2, 'AB'), (11, 'Jackson', 30, 2, 2, 'AB') ON DUPLICATE KEY UPDATE `id`=`id`;"
```

#### to_create_sql

You can call `to_create_sql` on any ActiveRecord model clas to get create table SQL of the model class / table.

#### t

You can call `t` method on any ActiveRecord model instance to print a pretty table of attributes names and values of the object.

```
ARQL ❯ Person.last.t
+----------------|-----------------|------------------|---------+
| Attribute Name | Attribute Value | SQL Type         | Comment |
+----------------|-----------------|------------------|---------+
| id             | 11              | int(11) unsigned |         |
| name           | Jackson         | varchar(64)      |         |
| age            | 30              | int(11)          |         |
| gender         | 2               | int(4)           |         |
| grade          | 2               | int(4)           |         |
| blood_type     | AB              | varchar(4)       |         |
+----------------|-----------------|------------------|---------+
```

#### v

The `v` method is for integration with Emacs org babel.

#### v for ActiveRecord instances

Call `v` method on any ActiveRecord model instance to print an Array which first element is `['Attribute Name', 'Attribute Value', 'SQL Type', 'Comment']`, and the second is `nil`, and the rest elements are attribute names and values of the object. In Emacs org-mode, is `:result` type is `value`(the default), this return value will be rendered as a pretty table.

```
ARQL ❯ Person.last.v
=> [["Attribute Name", "Attribute Value", "SQL Type", "Comment"],
 nil,
 ["id", 11, "int(11) unsigned", ""],
 ["name", "Jackson", "varchar(64)", ""],
 ["age", 30, "int(11)", ""],
 ["gender", 2, "int(4)", ""],
 ["grade", 2, "int(4)", ""],
 ["blood_type", "AB", "varchar(4)", ""]]
```

#### v for array

The `v` method is also available for arrays:

#### Array which only contains ActiveRecord instances

```
ARQL ❯ Person.all.to_a.v
=> [["id", "name", "age", "gender", "grade", "blood_type"],
 nil,
 [1, "Jack", 30, nil, nil, nil],
 [2, "Jack", 11, 1, nil, nil],
 [3, "Jack", 12, 1, nil, nil],
 [4, "Jack", 30, 1, nil, nil],
 [5, "Jack", 12, 2, nil, nil],
 [6, "Jack", 2, 2, 2, nil],
 [7, "Jack", 3, 2, 2, nil],
 [8, "Jack", 30, 2, 2, "AB"],
 [9, "Jack", 30, 2, 2, "AB"],
 [10, "Jack", 30, 2, 2, "AB"],
 [11, "Jackson", 30, 2, 2, "AB"]]
```

#### Array which only contains same-structured Hash objects

```
ARQL ❯ arr = [{name: 'Jack', age: 10}, {name: 'Lucy', age: 20}]
=> [{:name=>"Jack", :age=>10}, {:name=>"Lucy", :age=>20}]
ARQL ❯ arr.v
=> [[:name, :age], nil, ["Jack", 10], ["Lucy", 20]]
```

#### sql

Use `sql` method to execute raw SQL statements:

```
ARQL ❯ rs = sql 'select count(0) from person;'
=> #<ActiveRecord::Result:0x00007fd1f8026ad0 @column_types={}, @columns=["count(0)"], @hash_rows=nil, @rows=[[11]]>
ARQL ❯ rs.rows
=> [[11]]
```

#### JSON convertion and prints

Call `j` on any object to get JSON presentation of it, and `jj` to get pretty-printed JSON presentation.

Use `jp` to print JSON, `jjp` to pretty print.

#### String#p

The `p` methods is defined as:

```
class String
  def p
    puts self
  end
end
```

#### $C

Arql assigns `ActiveRecord::Base.connection` object to the global available `$C`

The `sql` method in above description is actually `$C.exec_query` in fact, and other methods of `$C` is also pretty helpful:

##### Create a table

```
ARQL ❯ $C.create_table :post, id: false, primary_key: :id do |t|
ARQL ❯   t.column :id, :bigint, precison: 19, comment: 'ID'
ARQL ❯   t.column :name, :string, comment: '名称'
ARQL ❯   t.column :gmt_created, :datetime, comment: '创建时间'
ARQL ❯   t.column :gmt_modified, :datetime, comment: '最后修改时间'
ARQL ❯ end
```

##### Add a column

```
$C.add_column :post, :note, :string, comment: '备注'
```

##### Modify a column

```
$C.change_column :post, :note, :text, comment: '备注'
```

##### Delete a column

```
$C.remove_column :post, :note
```
##### Delete a table

```
$C.drop_table :post
```

##### Add an index

```
ARQL ❯ $C.add_index :post, :name
ARQL ❯ $C.add_index(:accounts, [:branch_id, :party_id], unique: true, name: 'by_branch_party')
```

### Use with Emacs org babel

Here is a [ob-arql](https://github.com/lululau/spacemacs-layers/blob/master/ob-arql/local/ob-arql/ob-arql.el) for integration with Emacs org babel.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lululau/arql. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/lululau/arql/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Arql project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/lululau/arql/blob/master/CODE_OF_CONDUCT.md).
