require File.dirname(__FILE__) + '/base'

describe Array do
	it "mixes commands into array" do
		[ 1,2,3 ].entries.should == [ 1, 2, 3 ]
	end

	it "can call head" do
		[ 1,2,3 ].head(1).should == [ 1 ]
	end

	it "can call tail" do
		[ 1,2,3 ].tail(1).should == [ 3 ]
	end
end
