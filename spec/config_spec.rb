require File.dirname(__FILE__) + '/base'

describe Rush::Config do
	before do
		@sandbox_dir = "/tmp/rush_config_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}"
		@config = Rush::Config.new(@sandbox_dir)
	end

	after do
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

	it "loads list of ssh tunnels" do
		system "echo host.example.com:123 > #{@sandbox_dir}/tunnels"
		@config.tunnels.should == { 'host.example.com' => 123 }
	end

	it "returns an empty hash if tunnels file is blank" do
		@config.tunnels.should == { }
	end

	it "saves a list of ssh tunnels" do
		@config.save_tunnels({ 'my.example.com' => 4000 })
		@config.tunnels_file.contents.should == "my.example.com:4000\n"
	end

	it "ensure_credentials_exist doesn't do anything if credentials already exist" do
		@config.credentials_file.write "dummy"
		@config.should_receive(:generate_credentials).exactly(0).times
		@config.ensure_credentials_exist
	end

	it "ensure_credentials_exist generates credentials file if they don't exist" do
		@config.should_receive(:generate_credentials)
		@config.ensure_credentials_exist
	end

	it "secret_characters returns valid characters for username or password" do
		@config.secret_characters.should be_kind_of(Array)
	end

	it "generate_secret products a random string for use in username and password" do
		@config.should_receive(:secret_characters).and_return(%w(a))
		@config.generate_secret(2, 2).should == "aa"
	end

	it "generate_credentials saves credentials" do
		@config.generate_credentials
		@config.credentials_file.contents.should match(/^.+:.+$/)
	end
end
