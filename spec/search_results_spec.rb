require File.dirname(__FILE__) + '/base'

describe Rush::SearchResults do
	before do
		@results = Rush::SearchResults.new(/pat/)
		@file = Rush::File.new("file")
	end

	it "returns its list of entries" do
		@results.add(@file, %w(a))
		@results.entries.should == [ @file ]
	end

	it "only returns each entry once no matter how many line matches it has" do
		@results.add(@file, %w(a b))
		@results.entries.should == [ @file ]
	end

	it "returns its list of matched lines" do
		@results.add(@file, %w(a b))
		@results.lines.should == %w(a b)
	end

	it "returns all lines for each entry in a flattened form" do
		file2 = Rush::File.new("another file")
		@results.add(@file, %w(a b))
		@results.add(file2, %w(c d))
		@results.lines.should == %w(a b c d)
	end

	it "returns a hash of entries_with_lines" do
		@results.add(@file, %w(a))
		@results.entries_with_lines.should == { @file => %w(a) }
	end

	it "mixes in Commands to operate like a dir or entry array" do
		@results.methods.include?("search").should be_true
	end

	it "mixes in Enumerable to behave like an array" do
		@results.add(@file, %w(a))
		@results.map { |e| e }.should == [ @file ]
	end
end
