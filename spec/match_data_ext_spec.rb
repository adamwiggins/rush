require File.dirname(__FILE__) + '/base'

describe MatchData do
	before(:each) do
		@match = "abc".match(/b/)
	end

	it "calculates the leadup on the line a pattern is found" do
		@match.leadup.should == 'a'
	end

	it "calculates the leadout on the line a pattern is found" do
		@match.leadout.should == 'c'
	end

	it "offers enhanced inspect display" do
		@match.inspect   # just confirm no exception thrown
	end
end
