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
		@config.save_history('test')
		@config.history_file.contents.should == YAML.dump('test')
	end

	it "loads the shell command history" do
		@config.save_history([1,2,3])
		@config.load_history.should == [1,2,3]
	end
end
