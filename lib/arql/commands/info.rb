require 'rainbow'

module Arql::Commands
  module Info
    class << self
      def db_info
        <<~EOF

        Database Connection Information:

            Active:    #{color_boolean(ActiveRecord::Base.connection.active?)}
            Host:      #{Arql::App.config[:host]}
            Port:      #{Arql::App.config[:port]}
            Username:  #{Arql::App.config[:username]}
            Password:  #{(Arql::App.config[:password] || '').gsub(/./, '*')}
            Database:  #{Arql::App.config[:database]}
            Adapter:   #{Arql::App.config[:adapter]}
            Encoding:  #{Arql::App.config[:encoding]}
            Pool Size: #{Arql::App.config[:pool]}
        EOF
      end

      def ssh_info
        <<~EOF

        SSH Connection Information:

            Active:     #{color_boolean(Arql::SSHProxy.active?)}
            Host:       #{Arql::App.config[:ssh][:host]}
            Port:       #{Arql::App.config[:ssh][:port]}
            Username:   #{Arql::App.config[:ssh][:user]}
            Password:   #{(Arql::App.config[:ssh][:password] || '').gsub(/./, '*')}
            Local Port: #{Arql::SSHProxy.local_ssh_proxy_port}
        EOF
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

    Pry.commands.block_command 'info' do
      puts Info::db_info
      puts Info::ssh_info if Arql::App.config[:ssh].present?
    end
  end
end
