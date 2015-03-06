# The commands module contains operations against Rush::File entries, and is
# mixed in to Rush::Entry and Array.  This means you can run these commands against a single
# file, a dir full of files, or an arbitrary list of files.
#
# Examples:
#
#   box['/etc/hosts'].search /localhost/       # single file
#   box['/etc/'].search /localhost/            # entire directory
#   box['/etc/**/*.conf'].search /localhost/   # arbitrary list
module Rush::Commands
  # The entries command must return an array of Rush::Entry items.  This
  # varies by class that it is mixed in to.
  def entries
    raise "must define me in class mixed in to for command use"
  end

  # Search file contents for a regular expression.  A Rush::SearchResults
  # object is returned.
  def search(pattern)
    entries.inject(Rush::SearchResults.new(pattern)) do |results, entry|
      if !entry.dir? and matches = entry.search(pattern)
        results.add(entry, matches)
      end
      results
    end
  end

  # Search and replace file contents.
  def replace_contents!(pattern, with_text)
    entries.each do |entry|
      entry.replace_contents!(pattern, with_text) unless entry.dir?
    end
  end

  # Count the number of lines in the contained files.
  def line_count
    entries.inject(0) do |count, entry|
      count + (entry.dir? ? 0 : entry.lines.size)
    end
  end

  # Invoke vi on one or more files - only works locally.
  def vi(*args)
    if self.class == Rush::Dir
      system "cd #{full_path}; vim"
    else
      open_with('vim', *args)
    end
  end
  alias_method :vim, :vi

  # Invoke TextMate on one or more files - only works locally.
  def mate(*args)
    open_with('mate', *args)
  end

  # Open file with xdg-open.
  # Usage:
  #   home.locate('mai_failz').open
  def open(*args)
    open_with('xdg-open', *args)
  end

  # Open file with any application you like.
  # Usage:
  #   home.locate('timetable').open_with :vim
  def open_with(app, *args, **opts)
    system open_command(app, *args, opts)
  end

  def output_of(app, *args, **opts)
    `#{open_command(app, *args, opts)}`
  end

  def open_command(app, *args, **opts)
    names = dir? ? '' : entries.map(&:to_s).join(' ')
    options = opts.map do |k, v|
      case
      when v == true || v == false then "-#{k}"
      when k == 'other' || k == :other then v
      else "-#{k} #{v}"
      end
    end.join(' ')
    "cd #{dirname}; #{app.to_s} #{names} #{options} #{args.join(' ')}"
  end
end
