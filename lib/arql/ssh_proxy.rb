require 'net/ssh/gateway'

module Arql
  class SSHProxy
    class << self

      attr_accessor :config, :ssh_gateway, :local_ssh_proxy_port

      def connect(config)
        @config = config
        @ssh_gateway = Net::SSH::Gateway.new(config[:host], config[:user], config.slice(:port, :password).symbolize_keys)
        @local_ssh_proxy_port = @ssh_gateway.open(config[:forward_host], config[:forward_port], config[:local_port])
      end

      def reconnect
        reconnect! unless @ssh_gateway.active?
      end

      def reconnect!
        @ssh_gateway.shutdown!
        @ssh_gateway = Net::SSH::Gateway.new(@config[:host], @config[:user], @config.slice(:port, :password).symbolize_keys)
        @ssh_gateway.open(config[:forward_host], config[:forward_port], @local_ssh_proxy_port)
      end

      def active?
        @ssh_gateway.active?
      end
    end
  end
end
