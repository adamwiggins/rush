require File.dirname(__FILE__) + '/base'

describe Rush::EmbeddableShell do
	before do
		@shell = Rush::EmbeddableShell.new
	end

	it "should execute unknown methods against a Rush::Shell instance" do
		@shell.root.class.should == Rush::Dir
	end
	
	it "should executes a block as if it were inside the shell" do
		@shell.execute_in_shell {
			root.class.should == Rush::Dir
		}
	end
end
