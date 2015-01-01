require_relative 'base'

describe Rush::Access do
	before do
		@access = Rush::Access.new
	end

	it "has roles: user, group, other" do
		@access.class.roles == %w(user group other)
	end

	it "has permissions: read, write, execute" do
		@access.class.permissions == %w(read write execute)
	end

	it "gets parts from a one-part symbol like :user" do
		expect(@access.parts_from(:user)).to eq(%w(user))
	end

	it "gets parts from a two-part symbol like :read_write" do
		expect(@access.parts_from(:read_write)).to eq(%w(read write))
	end

	it "allows use of 'and' in multipart symbols, like :user_and_group" do
		expect(@access.parts_from(:user_and_group)).to eq( %w(user group))
	end

	it "extract_list verifies that all the parts among the valid choices" do
		expect(@access).to receive(:parts_from).with(:red_green).and_return(%w(red green))
		expect(@access.extract_list('type', :red_green, %w(red blue green))).to eq(%w(red green))
	end

	it "extract_list raises a BadAccessSpecifier when there is part not in the list of choices" do
		expect do
			@access.extract_list('role', :user_bork, %w(user group))
		end.to raise_error(Rush::BadAccessSpecifier, "Unrecognized role: bork")
	end

	it "sets one value in the matrix of permissions and roles" do
		@access.set_matrix(%w(read), %w(user))
		expect(@access.user_can_read).to eq(true)
	end

	it "sets two values in the matrix of permissions and roles" do
		@access.set_matrix(%w(read), %w(user group))
		expect(@access.user_can_read).to eq(true)
		expect(@access.group_can_read).to eq(true)
	end

	it "sets four values in the matrix of permissions and roles" do
		@access.set_matrix(%w(read write), %w(user group))
		expect(@access.user_can_read).to eq(true)
		expect(@access.group_can_read).to eq(true)
		expect(@access.user_can_write).to eq(true)
		expect(@access.group_can_write).to eq(true)
	end

	it "parse options hash" do
		@access.parse(:user_can => :read)
		expect(@access.user_can_read).to eq(true)
	end

	it "generates octal permissions from its member vars" do
		@access.user_can_read = true
		expect(@access.octal_permissions).to eq(0400)
	end

	it "generates octal permissions from its member vars" do
		@access.user_can_read = true
		@access.user_can_write = true
		@access.user_can_execute = true
		@access.group_can_read = true
		@access.group_can_execute = true
		expect(@access.octal_permissions).to eq(0750)
	end

	it "applies its settings to a file" do
		file = "/tmp/rush_spec_#{Process.pid}"
		begin
			system "rm -rf #{file}; touch #{file}; chmod 770 #{file}"
			@access.user_can_read = true
			@access.apply(file)
			expect(`ls -l #{file}`).to match(/^-r--------/)
		ensure
			system "rm -rf #{file}; touch #{file}"
		end
	end

	it "serializes itself to a hash" do
		@access.user_can_read = true
		expect(@access.to_hash).to eq({
			:user_can_read => 1, :user_can_write => 0, :user_can_execute => 0,
			:group_can_read => 0, :group_can_write => 0, :group_can_execute => 0,
			:other_can_read => 0, :other_can_write => 0, :other_can_execute => 0,
		})
	end

	it "unserializes from a hash" do
		@access.from_hash(:user_can_read => '1')
		expect(@access.user_can_read).to eq(true)
	end

	it "initializes from a serialized hash" do
		expect(@access.class).to receive(:new).and_return(@access)
		expect(@access.class.from_hash(:user_can_read => '1')).to eq(@access)
		expect(@access.user_can_read).to eq(true)
	end

	it "initializes from a parsed options hash" do
		expect(@access.class).to receive(:new).and_return(@access)
		expect(@access.class.parse(:user_and_group_can => :read)).to eq(@access)
		expect(@access.user_can_read).to eq(true)
	end

	it "converts and octal integer into an array of integers" do
		expect(@access.octal_integer_array(0740)).to eq([ 7, 4, 0 ])
	end

	it "filters out anything above the top three digits (File.stat returns some extra data there)" do
		expect(@access.octal_integer_array(0100644)).to eq([ 6, 4, 4 ])
	end

	it "taskes permissions from an octal representation" do
		@access.from_octal(0644)
		expect(@access.user_can_read).to eq(true)
		expect(@access.user_can_write).to eq(true)
		expect(@access.user_can_execute).to eq(false)
	end

	it "computes a display hash by dropping false keys and converting the 1s to trues" do
		expect(@access).to receive(:to_hash).and_return(:red => 1, :green => 0, :blue => 1)
		expect(@access.display_hash).to eq({ :red => true, :blue => true })
	end
end
