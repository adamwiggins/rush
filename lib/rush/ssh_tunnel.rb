require 'net/ssh'

# Internal class for managing an ssh tunnel, across which relatively insecure
#
class Rush::SshTunnel
  attr_reader :connection, :transport, :host, :user, :password
  attr_accessor :config

  def initialize(host, user, password = nil)
    @host = host
    @user = user
    @password = password
  end

  def connect
    @connection = establish_tunnel(host, user, password: password)
  end

  def disconnect
    connect.close
    transport.close
  end

  def establish_tunnel(host, user, options = {})
    options = { user: user, host_name: host, logger: Logger.new(STDERR) }
    options[:logger].level = Logger::INFO
    @transport = Net::SSH::Transport::Session.new(host, options)
    auth = Net::SSH::Authentication::Session.new(transport, options)
    args = ['ssh-connection', user, options.delete(:password)].reject(&:nil?)
    if auth.authenticate(*args)
      Net::SSH::Connection::Session.new(transport, options)
    else
      fail SshFailed, 'Authentication failed'
    end
  end

  def send(command)
    connection.exec! command
  end

  def config
    @config ||= Rush::Config.new
  end

  class SshFailed < StandardError; end
end
