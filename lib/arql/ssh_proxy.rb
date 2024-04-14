require 'net/ssh/gateway'
require 'arql/ssh_proxy_patch'

module Arql
  class SSHProxy
    attr_accessor :config, :ssh_gateway, :local_ssh_proxy_port

    def initialize(config)
      print "Establishing SSH connection to #{config[:host]}:#{config[:port]}"
      @config = config
      @ssh_gateway = Net::SSH::Gateway.new(config[:host], config[:user], config.slice(:port, :password).symbolize_keys.merge(keepalive: true, keepalive_interval: 30, loop_wait: 1))
      @local_ssh_proxy_port = @ssh_gateway.open(config[:forward_host], config[:forward_port], config[:local_port])
      print "\u001b[2K"
      puts "\rSSH connection to #{config[:host]}:#{config[:port]} established"
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

    def database_host_port
      {
        host: '127.0.0.1',
        port: @local_ssh_proxy_port
      }
    end
  end
end
