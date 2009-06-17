Gem::Specification.new do |s|
	s.name = "rush"
	s.version = "0.6"
	s.summary = "A Ruby replacement for bash+ssh."
	s.description = "A Ruby replacement for bash+ssh, providing both an interactive shell and a library.  Manage both local and remote unix systems from a single client."
	s.author = "Adam Wiggins"
	s.email = "adam@heroku.com"
	s.homepage = "http://rush.heroku.com/"
	s.rubyforge_project = "ruby-shell"

	s.add_dependency 'mongrel'
	s.add_dependency 'session'

	s.platform = Gem::Platform::RUBY
	s.has_rdoc = true
	
	s.files = %w(
		Rakefile README.rdoc rush.gemspec
		bin/rush bin/rushd
		lib/rush.rb
		lib/rush/access.rb lib/rush/array_ext.rb lib/rush/box.rb lib/rush/commands.rb
		lib/rush/config.rb lib/rush/dir.rb lib/rush/embeddable_shell.rb lib/rush/entry.rb
		lib/rush/exceptions.rb lib/rush/file.rb lib/rush/find_by.rb lib/rush/fixnum_ext.rb
		lib/rush/head_tail.rb lib/rush/local.rb lib/rush/process.rb lib/rush/process_set.rb
		lib/rush/remote.rb lib/rush/search_results.rb lib/rush/server.rb lib/rush/shell.rb
		lib/rush/ssh_tunnel.rb lib/rush/string_ext.rb
		spec/access_spec.rb spec/array_ext_spec.rb spec/base.rb spec/box_spec.rb
		spec/commands_spec.rb spec/config_spec.rb spec/dir_spec.rb spec/embeddable_shell_spec.rb
		spec/entry_spec.rb spec/file_spec.rb spec/find_by_spec.rb spec/fixnum_ext_spec.rb
		spec/local_spec.rb spec/process_set_spec.rb spec/process_spec.rb spec/remote_spec.rb
		spec/rush_spec.rb spec/search_results_spec.rb spec/shell_spec.rb spec/ssh_tunnel_spec.rb
		spec/string_ext_spec.rb
	)

	s.require_path = "lib"
	s.bindir = "bin"
	s.executables = [ "rush", "rushd" ]
end
