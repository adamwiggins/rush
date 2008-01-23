require File.dirname(__FILE__) + '/base'

describe Rush::EntryArray do
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

	it "greps the contents of a list of files" do
		@dir.files.grep(/thing_to_find/).should == @dir.make_entries(@filename)
	end

	it "greps a dir directly" do
		@dir.grep(/thing_to_find/).should == @dir.make_entries(@filename)
	end
end
