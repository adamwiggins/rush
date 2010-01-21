# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rush}
  s.version = "0.6.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Wiggins"]
  s.date = %q{2010-01-20}
  s.description = %q{A Ruby replacement for bash+ssh, providing both an interactive shell and a library.  Manage both local and remote unix systems from a single client.}
  s.email = %q{adam@heroku.com}
  s.executables = ["rush", "rushd"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/rush",
     "bin/rushd",
     "lib/rush.rb",
     "lib/rush/access.rb",
     "lib/rush/array_ext.rb",
     "lib/rush/box.rb",
     "lib/rush/commands.rb",
     "lib/rush/config.rb",
     "lib/rush/dir.rb",
     "lib/rush/embeddable_shell.rb",
     "lib/rush/entry.rb",
     "lib/rush/exceptions.rb",
     "lib/rush/file.rb",
     "lib/rush/find_by.rb",
     "lib/rush/fixnum_ext.rb",
     "lib/rush/head_tail.rb",
     "lib/rush/local.rb",
     "lib/rush/process.rb",
     "lib/rush/process_set.rb",
     "lib/rush/remote.rb",
     "lib/rush/search_results.rb",
     "lib/rush/server.rb",
     "lib/rush/shell.rb",
     "lib/rush/ssh_tunnel.rb",
     "lib/rush/string_ext.rb",
     "spec/access_spec.rb",
     "spec/array_ext_spec.rb",
     "spec/base.rb",
     "spec/box_spec.rb",
     "spec/commands_spec.rb",
     "spec/config_spec.rb",
     "spec/dir_spec.rb",
     "spec/embeddable_shell_spec.rb",
     "spec/entry_spec.rb",
     "spec/file_spec.rb",
     "spec/find_by_spec.rb",
     "spec/fixnum_ext_spec.rb",
     "spec/local_spec.rb",
     "spec/process_set_spec.rb",
     "spec/process_spec.rb",
     "spec/remote_spec.rb",
     "spec/rush_spec.rb",
     "spec/search_results_spec.rb",
     "spec/shell_spec.rb",
     "spec/ssh_tunnel_spec.rb",
     "spec/string_ext_spec.rb"
  ]
  s.homepage = %q{http://rush.heroku.com/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ruby-shell}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A Ruby replacement for bash+ssh.}
  s.test_files = [
    "spec/access_spec.rb",
     "spec/array_ext_spec.rb",
     "spec/base.rb",
     "spec/box_spec.rb",
     "spec/commands_spec.rb",
     "spec/config_spec.rb",
     "spec/dir_spec.rb",
     "spec/embeddable_shell_spec.rb",
     "spec/entry_spec.rb",
     "spec/file_spec.rb",
     "spec/find_by_spec.rb",
     "spec/fixnum_ext_spec.rb",
     "spec/local_spec.rb",
     "spec/process_set_spec.rb",
     "spec/process_spec.rb",
     "spec/remote_spec.rb",
     "spec/rush_spec.rb",
     "spec/search_results_spec.rb",
     "spec/shell_spec.rb",
     "spec/ssh_tunnel_spec.rb",
     "spec/string_ext_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<session>, [">= 0"])
    else
      s.add_dependency(%q<session>, [">= 0"])
    end
  else
    s.add_dependency(%q<session>, [">= 0"])
  end
end
