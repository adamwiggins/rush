require File.dirname(__FILE__) + '/base'

describe String do
	before do
		@string = "abc"
	end

	it "heads from the front of the string" do
		@string.head(1).should == 'a'
	end

	it "tails from the back of the string" do
		@string.tail(1).should == 'c'
	end

	it "gives the whole string when head exceeds length" do
		@string.head(999).should == @string
	end

	it "gives the whole string when tail exceeds length" do
		@string.tail(999).should == @string
	end
end
