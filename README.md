# Arql

  Arql is a simple utility gem which combines Rails ActiveRecord and Pry together, with additional helpful Pry commands.
  You can use this utility as your SQL editor and querier if you are a Ruby guy.

## Installation

Execute:

    $ gem install arql

If system permission problems occurs, try with sudo:

    $ sudo gem install arql

## Usage

### Command Line options

```
Usage: arql [options] [ruby file]

  If neither [ruby file] nor -e option specified, a Pry REPL will be launched,
  otherwise the specified ruby file or -e option value will be run, and no REPL launched

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

### Use as a REPL
### Use as code Interpreter
### Additional Pry commands
### Config file
### Use with Emacs org babel

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lululau/arql. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/lululau/arql/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Arql project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/lululau/arql/blob/master/CODE_OF_CONDUCT.md).
