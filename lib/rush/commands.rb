# The commands module contains operations against Rush::File entries, and is
# mixed in to Rush::Entry and Array.
# This means you can run these commands against a single
# file, a dir full of files, or an arbitrary list of files.
#
# Examples:
#
#   box['/etc/hosts'].search /localhost/       # single file
#   box['/etc/'].search /localhost/            # entire directory
#   box['/etc/**/*.conf'].search /localhost/   # arbitrary list
#
module Rush::Commands
  # The entries command must return an array of Rush::Entry items.  This
  # varies by class that it is mixed in to.
  def entries
    fail 'must define me in class mixed in to for command use'
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

  # Open file with $EDITOR.
  #
  def edit(*args)
    open_with ENV['EDITOR'], *args
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
  #   home['.vimrc'].vim { other: '+55', x: true, u: 'other_vimrc', cmd: 'ls' }
  #   home['my_app'].rails :c, env: { rails_env: 'test' } # environment vars
  def open_with(app, *args)
    system(*open_command(app, *args))
  end

  def output_of(app, *args)
    `#{open_command(app, *args)}`
  end

  def opt_to_s(k, v)
    key = k.size == 1 ? "-#{k}" : "--#{k}"
    case
    when v == true then key
    when k == 'other' || k == :other then v
    else "#{key} #{v}"
    end
  end

  def open_command(app, *args)
    opts = args.last.is_a?(Hash) ? args.pop : {}
    names = dir? ? '' : entries.map { |x| Rush.quote x.to_s }.join(' ')
    options = opts
      .reject { |k, _| k == :env }
      .map    { |k, v| opt_to_s(k, v) }
      .join(' ')
    dir = Rush.quote dirname.to_s
    cmd = "cd #{dir}; #{app} #{names} #{options} #{args.join(' ')}"
    if vars = opts[:env]
      env = vars.inject({}) { |r, (k, v)| r.merge(k.to_s.upcase => v.to_s) }
    end
    vars ? [env, cmd] : cmd
  end
end
