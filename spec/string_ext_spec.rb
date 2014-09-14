require_relative 'base'

describe String do
	before do
		@string = "abc"
	end

	it "heads from the front of the string" do
		expect(@string.head(1)).to eq 'a'
	end

	it "tails from the back of the string" do
		expect(@string.tail(1)).to eq 'c'
	end

	it "gives the whole string when head exceeds length" do
		expect(@string.head(999)).to eq @string
	end

	it "gives the whole string when tail exceeds length" do
		expect(@string.tail(999)).to eq @string
	end
end
