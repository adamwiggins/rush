# Files are a subclass of Rush::Entry.  Most of the file-specific operations
# relate to manipulating the file's contents, like search and replace.
class Rush::File < Rush::Entry
  def dir?
    false
  end

  def dirname
    ::File.dirname full_path
  end

  # Create a blank file.
  def create
    write('')
    self
  end
  alias_method :touch, :create

  # Hardlink the file (see File.ln for options)
  def link(dst, options = {})
    connection.ln(full_path, dst, options)
    self.class.new(dst, box)
  end

  # Size in bytes on disk.
  def size
    stat[:size]
  end

  # Raw contents of the file.  For non-text files, you probably want to avoid
  # printing this on the screen.
  def contents
    connection.file_contents(full_path)
  end

  alias_method :read, :contents
  alias_method :cat, :contents

  # Write to the file, overwriting whatever was already in it.
  #
  # Example: file.write "hello, world\n"
  def write(new_contents)
    connection.write_file(full_path, new_contents)
  end

  # Append new contents to the end of the file, keeping what was in it.
  def append(contents)
    connection.append_to_file(full_path, contents)
  end
  alias_method :<<, :append

  # Return an array of lines from the file, similar to stdlib's File#readlines.
  def lines
    contents.split("\n")
  end

  # Search the file's for a regular expression.  Returns nil if no match, or
  # each of the matching lines in its entirety.
  #
  # Example: box['/etc/hosts'].search(/localhost/) # -> [ "127.0.0.1 localhost\n", "::1 localhost\n" ]
  def search(pattern)
    matching_lines = lines.select { |line| line.match(pattern) }
    matching_lines.size == 0 ? nil : matching_lines
  end

  # Search-and-replace file contents.
  #
  # Example: box['/etc/hosts'].replace_contents!(/localhost/, 'local.host')
  def replace_contents!(pattern, replace_with)
    write contents.gsub(pattern, replace_with)
  end
  alias_method :gsub, :replace_contents!
  # Because I like vim.
  alias_method :s, :replace_contents!

  # Return the file's contents, or if it doesn't exist, a blank string.
  def contents_or_blank
    contents
  rescue Rush::DoesNotExist
    ""
  end

  # Count the number of lines in the file.
  def line_count
    lines.size
  end

  # Return an array of lines, or an empty array if the file does not exist.
  def lines_or_empty
    lines
  rescue Rush::DoesNotExist
    []
  end

  include Rush::Commands

  def entries
    [ self ]
  end
end
