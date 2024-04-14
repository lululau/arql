require 'arql/concerns'
module Kernel
  CSV_BOM = "\xef\xbb\xbf"

  include ::Arql::Concerns::GlobalDataDefinition

  def q(sql)
    if Arql::App.instance.environments.size > 1
      $stderr.puts "Multiple environments are defined. Please use Namespace::q() instread, where Namespace is the namespace module of one of the environments."
      return
    end
    Arql::App.instance.definitions.first.connection.exec_query(sql)
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
      package.serialize(File.expand_path(filename))
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

  def parse_json(filename)
    JSON.parse(IO.read(File.expand_path(filename)))
  end

  def within_namespace(namespace_pattern, &blk)
    if namespace_pattern.is_a?(Module)
      namespace_pattern.module_eval(&blk)
      return
    end
    definition = Arql::App.instance.definitions.find do |_, defi|
      case namespace_pattern
      when Symbol
        defi.namespace.to_s == namespace_pattern.to_s
      when String
        defi.namespace.to_s == namespace_pattern
      when Regexp
        defi.namespace.to_s =~ namespace_pattern
      end
    end
    if definition
      definition.last.namespace_module.module_eval(&blk)
      return
    end

    $stderr.puts "Namespace #{namespace_pattern.inspect} not found"
  end

  def within_env(env_name_pattern, &blk)
    definition = Arql::App.instance.definitions.find do |env_name, defi|
      case env_name_pattern
      when Symbol
        env_name == env_name_pattern.to_s
      when String
        env_name == env_name_pattern
      when Regexp
        env_name =~ env_name_pattern
      end
    end
    if definition
      definition.last.namespace_module.module_eval(&blk)
      return
    end

    $stderr.puts "Environment #{env_name_pattern.inspect} not found"
  end

  def models
    Arql::App.instance.definitions.flat_map do |_, definition|
      definition.namespace_module.models
    end
  end

  def table_names
    Arql::App.instance.definitions.flat_map do |_, definition|
      definition.namespace_module.tables
    end
  end

  def model_names
    Arql::App.instance.definitions.flat_map do |_, definition|
      definition.namespace_module.model_names
    end
  end
end