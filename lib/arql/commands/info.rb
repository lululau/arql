require 'rainbow'

module Arql::Commands
  module Info
    class << self
      def db_info(env_name_regexp)

        Arql::App.instance.definitions.map do |env_name, definition|
          next unless env_name =~ env_name_regexp
          config = Arql::App.config[:environments][env_name]
          <<~DB_INFO

          #{env_name} Database Connection Information:

              Active:    #{color_boolean(definition.connection.active?)}
              Host:      #{config[:host]}
              Port:      #{config[:port]}
              Username:  #{config[:username]}
              Password:  #{(config[:password] || '').gsub(/./, '*')}
              Database:  #{config[:database]}
              Adapter:   #{config[:adapter]}
              Encoding:  #{config[:encoding]}
              Pool Size: #{config[:pool]}
          DB_INFO
        end
      end

      def ssh_info(env_name_regexp)
        Arql::App.instance.definitions.map do |env_name, definition|
          next unless env_name =~ env_name_regexp
          config = Arql::App.config[:environments][env_name]
          next unless config[:ssh].present?
          <<~SSH_INFO

          #{env_name} SSH Connection Information:

              Active:     #{color_boolean(definition.ssh_proxy.active?)}
              Host:       #{config[:ssh][:host]}
              Port:       #{config[:ssh][:port]}
              Username:   #{config[:ssh][:user]}
              Password:   #{(config[:ssh][:password] || '').gsub(/./, '*')}
              Local Port: #{definition.ssh_proxy.local_ssh_proxy_port}
          SSH_INFO
        end
      end

      private

      def color_boolean(bool)
        if bool
          Rainbow('TRUE').green
        else
          Rainbow('FALSE').red
        end
      end
    end

    Pry.commands.block_command 'info' do |env_name_regexp|
      env_name_regexp ||= '.*'
      env_name_regexp = Regexp.new(env_name_regexp, Regexp::IGNORECASE)
      output.puts Info::db_info(env_name_regexp)
      output.puts Info::ssh_info(env_name_regexp)
    end
  end
end
