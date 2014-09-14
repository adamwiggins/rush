require_relative 'base'

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
		expect(File.directory?(@sandbox_dir)).to eq(true)
	end

	it "can access the history file" do
		expect(@config.history_file).to be_kind_of(Rush::File)
	end

	it "saves the shell command history" do
		@config.save_history(%w(1 2 3))
		expect(@config.history_file.contents).to eq("1\n2\n3\n")
	end

	it "loads the shell command history" do
		@config.save_history(%w(1 2 3))
		expect(@config.load_history).to eq(%w(1 2 3))
	end

	it "loads a blank history if no history file" do
		expect(@config.load_history).to eq([])
	end

	it "loads the env file" do
		@config.env_file.write('abc')
		expect(@config.load_env).to eq('abc')
	end

	it "loads nothing if env file does not exist" do
		expect(@config.load_env).to eq('')
	end

	it "loads the commands file" do
		@config.commands_file.write('abc')
		expect(@config.load_commands).to eq('abc')
	end

	it "loads nothing if commands file does not exist" do
		expect(@config.load_commands).to eq('')
	end

	it "loads usernames and password for rushd" do
		system "echo 1:2 > #{@sandbox_dir}/passwords"
		system "echo a:b >> #{@sandbox_dir}/passwords"
		expect(@config.passwords).to eq({ '1' => '2', 'a' => 'b' })
	end

	it "loads blank hash if no passwords file" do
		expect(@config.passwords).to eq({})
	end

	it "loads credentials for client connecting to server" do
		system "echo user:pass > #{@sandbox_dir}/credentials"
		expect(@config.credentials_user).to eq 'user'
		expect(@config.credentials_password).to eq 'pass'
	end

	it "loads list of ssh tunnels" do
		system "echo host.example.com:123 > #{@sandbox_dir}/tunnels"
		expect(@config.tunnels).to eq({ 'host.example.com' => 123 })
	end

	it "returns an empty hash if tunnels file is blank" do
		expect(@config.tunnels).to eq({})
	end

	it "saves a list of ssh tunnels" do
		@config.save_tunnels({ 'my.example.com' => 4000 })
		expect(@config.tunnels_file.contents).to eq "my.example.com:4000\n"
	end

	it "ensure_credentials_exist doesn't do anything if credentials already exist" do
		@config.credentials_file.write "dummy"
		expect(@config).to receive(:generate_credentials).exactly(0).times
		@config.ensure_credentials_exist
	end

	it "ensure_credentials_exist generates credentials file if they don't exist" do
		expect(@config).to receive(:generate_credentials)
		@config.ensure_credentials_exist
	end

	it "secret_characters returns valid characters for username or password" do
		expect(@config.secret_characters).to be_kind_of(Array)
	end

	it "generate_secret products a random string for use in username and password" do
		expect(@config).to receive(:secret_characters).and_return(%w(a))
		expect(@config.generate_secret(2, 2)).to eq "aa"
	end

	it "generate_credentials saves credentials" do
		@config.generate_credentials
		expect(@config.credentials_file.contents).to match(/^.+:.+$/)
	end
end
