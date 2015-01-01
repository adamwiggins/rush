require_relative 'base'

describe Fixnum do
	before do
		@num = 2
	end

	it "counts kb" do
		expect(@num.kb).to eq 2*1024
	end

	it "counts mb" do
		expect(@num.mb).to eq 2*1024*1024
	end

	it "counts gb" do
		expect(@num.gb).to eq 2*1024*1024*1024
	end
end
