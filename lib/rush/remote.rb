require 'net/ssh'

module Rush
  # wrapper of command
  #   sshfs '-o idmap=user <user_name>@<server_address>:<path> <local_path>'
  #
  class Connection::Remote
    attr_reader :local_path, :full_remote_path, :remote_path, :remote_server, :remote_user

    def initialize(full_remote_path, local_path)
      local_path = local_path.full_path if local_path.respond_to?(:full_path)
      @full_remote_path = full_remote_path
      @local_path = Rush::Dir.new(local_path)
      @local_path.create unless @local_path.exists?
      @remote_user, server_and_path = *full_remote_path.split('@', 2)
      @remote_server, @remote_address = *server_and_path.split(':', 2)
    end

    def connect
      system "sshfs -o idmap=user #{full_remote_path} #{local_path}"
    end
    alias_method :mount, :connect

    def disconnect
      system "fusermount -u #{local_path.full_path}"
    end
    alias_method :umount, :disconnect

    def method_missing(meth, *args, &block)
      @local_path.send(meth, *args, &block)
    end
  end
end
