module Rush
	# Base class for all rush exceptions.
	class Exception < ::Exception; end

	# Client was not authorized by remote server; check credentials.
	class NotAuthorized < Exception; end

	# Failed to transmit to the remote server; check if the ssh tunnel is alive,
	# and rushd is listening on the other end.
	class FailedTransmit < Exception; end

	# The entry (file or dir) referenced does not exist.  Message is the entry's full path.
	class DoesNotExist < Exception; end
end
