require File.dirname(__FILE__) + '/base'

describe Rush::File do
	before do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@filename = "#{@sandbox_dir}/test_file"
		@contents = "1234"
		system "echo #{@contents} > #{@filename}"
		@contents += "\n"

		@file = Rush::File.new(@filename)
	end

	after do
		system "rm -rf #{@sandbox_dir}"
	end

	it "is a child of Rush::Entry" do
		@file.should be_kind_of(Rush::Entry)
	end

	it "is not a dir" do
		@file.should_not be_dir
	end

	it "can create itself as a blank file, and return itself" do
		create_me = Rush::File.new("#{@sandbox_dir}/create_me")
		create_me.create.should == create_me
		File.exists?("#{@sandbox_dir}/create_me").should == true
	end

	it "knows its size in bytes" do
		@file.size.should == @contents.length
	end

	it "can read its contents" do
		@file.contents.should == @contents
	end

	it "read is an alias for contents" do
		@file.read.should == @contents
	end

	it "can write new contents" do
		@file.write('write test')
		@file.contents.should == 'write test'
	end

	it "can count the number of lines it contains" do
		@file.write("1\n2\n3\n")
		@file.line_count.should == 3
	end

	it "searches its contents for matching lines" do
		@file.write("a\n1\nb\n2\n")
		@file.search(/\d/).should == %w(1 2)
	end

	it "search returns nil if no lines match" do
		@file.write("a\nb\nc\n")
		@file.search(/\d/).should be_nil
	end

	it "find-in-file replace" do
		@file.replace_contents!(/\d/, 'x')
		@file.contents.should == "xxxx\n"
	end

	it "can destroy itself" do
		@file.destroy
		::File.exists?(@filename).should be_false
	end

	it "can fetch contents or blank if doesn't exist" do
		Rush::File.new('/does/not/exist').contents_or_blank.should == ""
	end

	it "can fetch lines, or empty if doesn't exist" do
		Rush::File.new('/does/not/exist').lines_or_empty.should == []
	end
end
