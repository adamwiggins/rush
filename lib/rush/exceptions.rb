module Rush
  # Base class for all rush exceptions.
  class Exception < ::RuntimeError; end

  # Client was not authorized by remote server; check credentials.
  class NotAuthorized < Exception; end

  # rushd is not running on the remote box.
  class RushdNotRunning < Exception; end

  # An unrecognized status code was returned by rushd.
  class FailedTransmit < Exception; end

  # The entry (file or dir) referenced does not exist.  Message is the entry's full path.
  class DoesNotExist < Exception; end

  # The bash command had a non-zero return value.  Message is stderr.
  class BashFailed < Exception; end

  # Attempts to rename, copy, or otherwise place an entry into a dir that
  # already contains an entry by that name will fail with this exception.
  class NameAlreadyExists < Exception; end

  # Do not use rename or duplicate with a slash; use copy_to or move_to instead.
  class NameCannotContainSlash < Exception; end

  # You cannot move or copy entries to a path that is not a dir (should end with trailing slash).
  class NotADir < Exception; end

  # A user or permission value specified to set access was not valid.
  class BadAccessSpecifier < Exception; end
end
