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

	it "loads the env file" do
		@config.env_file.write('abc')
		@config.load_env.should == 'abc'
	end

	it "loads nothing if env file does not exist" do
		@config.load_env.should == ""
	end

	it "loads the commands file" do
		@config.commands_file.write('abc')
		@config.load_commands.should == 'abc'
	end

	it "loads nothing if commands file does not exist" do
		@config.load_commands.should == ""
	end

	it "loads usernames and password for rushd" do
		system "echo 1:2 > #{@sandbox_dir}/passwords"
		system "echo a:b >> #{@sandbox_dir}/passwords"
		@config.passwords.should == { '1' => '2', 'a' => 'b' }
	end

	it "loads blank hash if no passwords file" do
		@config.passwords.should == { }
	end

	it "loads credentials for client connecting to server" do
		system "echo user:pass > #{@sandbox_dir}/credentials"
		@config.credentials_user.should == 'user'
		@config.credentials_password.should == 'pass'
	end
end
