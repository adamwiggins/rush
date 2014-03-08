# An instance of this class is returned by Rush::Commands#search.  It contains
# both the list of entries which matched the search, as well as the raw line
# matches.  These methods get equivalent functionality to "grep -l" and "grep -h".
#
# SearchResults mixes in Rush::Commands so that you can chain multiple searches
# or do file operations on the resulting entries.
#
# Examples:
#
#   myproj['**/*.rb'].search(/class/).entries.size
#   myproj['**/*.rb'].search(/class/).lines.size
#   myproj['**/*.rb'].search(/class/).copy_to other_dir
class Rush::SearchResults
  include Rush::Commands
  include Enumerable

  attr_reader :entries, :lines, :entries_with_lines, :pattern

  # Make a blank container.  Track the pattern so that we can colorize the
  # output to show what was matched.
  def initialize(pattern)
    # Duplication of data, but this lets us return everything in the exact
    # order it was received.
    @pattern = pattern
    @entries = []
    @entries_with_lines = {}
    @lines = []
  end

  # Add a Rush::Entry and the array of string matches.
  def add(entry, lines)
    # this assumes that entry is unique
    @entries << entry
    @entries_with_lines[entry] = lines
    @lines += lines
    self
  end
  alias_method :<<, :add

  def to_s
    widest = entries.map { |k| k.full_path.length }.max
    entries_with_lines.inject('') do |result, (entry, lines)|
      result << entry.full_path
      result << ' ' * (widest - entry.full_path.length + 2)
      result << "=> "
      result << colorize(lines.first.strip.head(30))
      lines.each { |line| result << "\t" << line << "\n" }
      result << "\n"
    end
  end

  def each(&block)
    @entries.each(&block)
  end

  def colorize(line)
    lowlight + line.gsub(/(#{pattern.source})/, "#{hilight}\\1#{lowlight}") + normal
  end

  def hilight
    "\e[34;1m"
  end

  def lowlight
    "\e[37;2m"
  end

  def normal
    "\e[0m"
  end
end
