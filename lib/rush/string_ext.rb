class String
	include Rush::HeadTail

  def less
    IO.popen('less', 'w') { |f| f.puts self }
  end
  alias_method :pager, :less

  def dir?
    ::Dir.exists? self
  end
end
