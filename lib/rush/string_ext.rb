class String
	include Rush::HeadTail
	
	def | (command, box = Rush::Box.new('localhost'))
      box.bash(command, :user => nil, :stdin => self)
  end
end
