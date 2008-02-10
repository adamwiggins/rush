require File.dirname(__FILE__) + '/base'

describe Rush::Commands do
	before do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@filename = "test_file"
		system "echo thing_to_find > #{@sandbox_dir}/#{@filename}"
		system "echo dont_find_me > #{@sandbox_dir}/some_other_file"

		@dir = Rush::Dir.new(@sandbox_dir)
		@array = @dir.files
	end

	after do
		system "rm -rf #{@sandbox_dir}"
	end

	it "searches a list of files" do
		results = @dir.files.search(/thing_to_find/)
		results.should be_kind_of(Rush::SearchResults)
		results.entries.should == [ @dir[@filename] ]
		results.lines.should == [ "thing_to_find" ]
	end

	it "searches a dir" do
		@dir.search(/thing_to_find/).entries.should == [ @dir[@filename] ]
	end

	it "searchs a dir's nested files" do
		@dir.create_dir('sub').create_file('file').write('nested')
		@dir['**'].search(/nested/).entries.should == [ @dir['sub/file'] ]
	end

	it "search and replace contents on all files in the glob" do
		@dir['1'].create.write('xax')
		@dir['2'].create.write('-a-')
		@dir.replace_contents!(/a/, 'b')
		@dir['1'].contents.should == "xbx"
		@dir['2'].contents.should == "-b-"
	end

	it "counts lines of the contained files" do
		@dir.files.line_count.should == 2
	end
end
