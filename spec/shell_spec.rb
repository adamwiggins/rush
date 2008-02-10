require File.dirname(__FILE__) + '/base'
require File.dirname(__FILE__) + '/../bin/shell'

describe Rush::Shell do
	before do
		@shell = Rush::Shell.new
	end

	it "matches open path commands for readline tab completion" do
		@shell.path_parts("dir['app").should == [ "dir", "'", "app" ]
	end
end
