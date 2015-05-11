# A tiny wrapper around ENV['PATH']
class Rush::Path
  def self.executables
    ENV['PATH'].split(':')
      .select { |f| ::File.directory?(f) }
      .map { |x| Rush::Dir.new(x).entries.map(&:name) }
      .flatten
  end
end
