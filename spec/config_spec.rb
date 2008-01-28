require File.dirname(__FILE__) + '/base'

describe Rush::Config do
	before(:each) do
		@sandbox_dir = "/tmp/rush_config_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}"
		@config = Rush::Config.new(@sandbox_dir)
	end

	after(:each) do
		system "rm -rf #{@sandbox_dir}"
	end

	it "creates the dir" do
		File.directory?(@sandbox_dir).should be_true
	end

	it "can access the history file" do
		@config.history_file.class.should == Rush::File
	end

	it "saves the shell command history" do
		@config.save_history(%w(1 2 3))
		@config.history_file.contents.should == "1\n2\n3\n"
	end

	it "loads the shell command history" do
		@config.save_history(%w(1 2 3))
		@config.load_history.should == %w(1 2 3)
	end

	it "loads a blank history if no history file" do
		@config.load_history.should == []
	end
end
