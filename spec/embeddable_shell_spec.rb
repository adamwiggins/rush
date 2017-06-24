require_relative 'base'

describe Rush::EmbeddableShell do
	before do
		@shell = Rush::EmbeddableShell.new
	end

	it "should execute unknown methods against a Rush::Shell instance" do
		expect(@shell.root.class).to eq(Rush::Dir)
	end

	it "should executes a block as if it were inside the shell" do
		expect(@shell.execute_in_shell {
			root.class
		}).to eq Rush::Dir
	end
end
