class String
	include Rush::HeadTail

  def less
    IO.popen('less -R', 'w') { |f| f.puts self }
  end
  alias_method :pager, :less

  def dir?
    ::Dir.exists? self
  end

  def locate
    Rush::Dir.new(ENV['HOME']).locate self
  end

  def open_with(meth, *args, &block)
    if executables.include? meth.to_s
      system [meth.to_s, *args, self].join(' ')
    else
      raise 'No such executable. Maybe something wrong with PATH?'
    end
  end
  alias_method :e, :open_with

  def |(meth, *args, &block)
    Open3.capture2(meth, stdin_data: self).first
  end

  def executables
    Rush::Path.executables
  end
end
