require 'terminal-table'
require 'arql/table'

module Arql::Commands
  module Models
    class << self
      def filter_tables(env_name, definition, format, table_regexp=nil)
        result = ''
        if format.to_s == 'sql'
          result << '-- '
          result << "Environment: #{env_name}\n"
          result << "------------------------------\n\n"
        end
        if format.to_s == 'sql'
          definition.models.each do |model|
            if table_regexp? || ( model[:table] =~ table_regexp || model[:comment] =~ table_regexp )
              result << "-- Table: #{table_name}\n\n"
              result << definition.connection.exec_query("show create table `#{table_name}`").rows.last.last + ';'
            end
          end
        else
          tbl = Arql::Table.new("Environment: #{env_name}") { |t|
            t.headers = ['Table Name', 'Model Class', 'Abbr', 'Comment']
            definition.models.each do |model|
              if table_regexp.nil? || ( model[:table] =~ table_regexp || model[:comment] =~ table_regexp )
                t.body << [model[:table], model[:model].name, model[:abbr] || '', model[:comment] || '']
              end
            end
          }
          if $iruby && format.to_s == 'terminal'
            return tbl.to_iruby
          else
            result << tbl.to_terminal(format)
          end
        end
        result
      end

      def filter_columns(env_name, definition, format, column_regexp=nil)
        tbl = Arql::Table.new("Environment: #{env_name}") { |t|
          t.headers = ['Table', 'Model', 'Name', 'SQL Type', 'Ruby Type', 'Limit', 'Precision', 'Scale', 'Default', 'Nullable', 'Comment']
          definition.models.each do |model_def|
            model_class = model_def[:model]
            matched_columns = model_class.columns.select { |column| column.name =~ column_regexp || column.comment =~ column_regexp }
            next if matched_columns.empty?
            matched_columns.each do |column|
              t.body << [model_def[:table], model_class.name, column.name, column.sql_type,
                    column.sql_type_metadata.type, column.sql_type_metadata.limit || '',
                    column.sql_type_metadata.precision || '', column.sql_type_metadata.scale || '', column.default || '',
                    column.null, "#{model_def[:comment]} - #{column.comment}"]
            end
          end
        }

        if $iruby && format.to_s == 'terminal'
          return tbl.to_iruby
        else
          return tbl.to_terminal(format)
        end
      end
    end
  end

  Pry.commands.create_command 'm' do
    description 'List models or columns (specified by `-c`): m [-e env_name_regexp] -c [column_regexp] [table_regexp]'

    def options(opt)
      opt.on '-e', '--env', 'Environment name regexp', argument: true, as: String, required: false, default: nil
      opt.on '-f', '--format', 'Table format, available: terminal(default), md, org, sql', argument: true, as: String, required: false, default: 'terminal'
      opt.on '-c', '--column', 'Column name regexp', argument: true, as: String, required: false, default: nil
    end

    def process

      if opts[:format] == 'sql' && opts[:column]
        output.puts 'SQL format is not supported for column listing'
        return
      end

      env_names = opts[:env].try {|e| [e]}.presence || Arql::App.environments
      env_names = env_names.map { |e| e.start_with?('/') ? eval(e) : Regexp.new(e) }

      Arql::App.instance.definitions.each do |env_name, definition|
        next unless env_names.any? { |e| env_name =~ e }

        output.puts
        if opts[:column]
          column_regexp = opts[:column]
          output.puts Models::filter_columns(env_name, definition, opts[:format], column_regexp.try { |e| e.start_with?('/') ? eval(e) : Regexp.new(e) })
        else
          table_regexp = args&.first
          output.puts Models::filter_tables(env_name, definition, opts[:format], table_regexp.try { |e| e.start_with?('/') ? eval(e) : Regexp.new(e) })
        end
      end
    end

  end

  Pry.commands.alias_command 'l', 'm'
end
