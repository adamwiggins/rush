require File.dirname(__FILE__) + '/base'

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
		@access.parts_from(:user).should == %w(user)
	end

	it "gets parts from a two-part symbol like :read_write" do
		@access.parts_from(:read_write).should == %w(read write)
	end

	it "allows use of 'and' in multipart symbols, like :user_and_group" do
		@access.parts_from(:user_and_group).should == %w(user group)
	end

	it "extract_list verifies that all the parts among the valid choices" do
		@access.should_receive(:parts_from).with(:red_green).and_return(%w(red green))
		@access.extract_list('type', :red_green, %w(red blue green)).should == %w(red green)
	end

	it "extract_list raises a BadAccessSpecifier when there is part not in the list of choices" do
		lambda do
			@access.extract_list('role', :user_bork, %w(user group))
		end.should raise_error(Rush::BadAccessSpecifier, "Unrecognized role: bork")
	end

	it "sets one value in the matrix of permissions and roles" do
		@access.set_matrix(%w(read), %w(user))
		@access.user_read.should == true
	end

	it "sets two values in the matrix of permissions and roles" do
		@access.set_matrix(%w(read), %w(user group))
		@access.user_read.should == true
		@access.group_read.should == true
	end

	it "sets four values in the matrix of permissions and roles" do
		@access.set_matrix(%w(read write), %w(user group))
		@access.user_read.should == true
		@access.group_read.should == true
		@access.user_write.should == true
		@access.group_write.should == true
	end

	it "parse options hash: user" do
		@access.parse(:user => 'joe')
		@access.user.should == 'joe'
	end

	it "parse options hash: group" do
		@access.parse(:group => 'users')
		@access.group.should == 'users'
	end

	it "parse options hash: permissions" do
		@access.parse(:read => :user)
		@access.user_read.should == true
	end
end
