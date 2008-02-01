require File.dirname(__FILE__) + '/base'

describe Array do
	it "mixes commands into array" do
		[ 1,2,3 ].entries.should == [ 1, 2, 3 ]
	end

	it "mixes commands into hash with keys as the entries" do
		{ 1 => 2, 3 => 4 }.entries.should == [ 1, 3 ]
	end
end
