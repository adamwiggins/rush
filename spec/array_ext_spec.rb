require File.dirname(__FILE__) + '/base'

describe Array do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@filename = "test_file"
		system "echo thing_to_find > #{@sandbox_dir}/#{@filename}"
		system "echo dont_find_me > #{@sandbox_dir}/some_other_file"

		@dir = Rush::Dir.new(@sandbox_dir)
		@array = @dir.files
	end

	after(:each) do
		system "rm -rf #{@sandbox_dir}"
	end

	it "searches a list of files" do
		@dir.files.search(/thing_to_find/).should be_kind_of(Hash)
		@dir.files.search(/thing_to_find/).keys.first.should == @dir[@filename]
		@dir.files.search(/thing_to_find/).values.first.to_a.should == [ "thing_to_find" ]
	end

	it "searches a dir" do
		@dir.search(/thing_to_find/).keys.first.should == @dir[@filename]
	end

	it "searchs a dir's nested files" do
		@dir.create_dir('sub').create_file('file').write('nested')
		@dir['**'].search(/nested/).keys.first.should == @dir['sub/file']
	end
end
