require File.dirname(__FILE__) + '/base'

describe Rush do
	it "fetches a local file path" do
		Rush['/etc/hosts'].full_path.should == '/etc/hosts'
	end

	it "fetches the dir of __FILE__" do
		Rush.dir(__FILE__).name.should == 'spec'
	end

	it "fetches the launch dir (aka current working directory or pwd)" do
		Dir.stub!(:pwd).and_return('/tmp')
		Rush.launch_dir.should == Rush::Box.new['/tmp/']
	end

	it "runs a bash command" do
		Rush.bash('echo hi').should == "hi\n"
	end

	it "gets the list of local processes" do
		Rush.processes.should be_kind_of(Rush::ProcessSet)
	end

	it "gets my process" do
		Rush.my_process.pid.should == Process.pid
	end
end
