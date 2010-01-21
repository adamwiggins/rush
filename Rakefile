require 'rake'

require 'jeweler'

Jeweler::Tasks.new do |s|
	s.name = "rush"
	s.summary = "A Ruby replacement for bash+ssh."
	s.description = "A Ruby replacement for bash+ssh, providing both an interactive shell and a library.  Manage both local and remote unix systems from a single client."
	s.author = "Adam Wiggins"
	s.email = "adam@heroku.com"
	s.homepage = "http://rush.heroku.com/"
	s.executables = [ "rush", "rushd" ]
	s.rubyforge_project = "ruby-shell"
	s.has_rdoc = true

	s.add_dependency 'session'
	
	s.files = FileList["[A-Z]*", "{bin,lib,spec}/**/*"]
end

Jeweler::GemcutterTasks.new

######################################################

require 'spec/rake/spectask'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Print specdocs"
Spec::Rake::SpecTask.new(:doc) do |t|
	t.spec_opts = ["--format", "specdoc", "--dry-run"]
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
	t.spec_files = FileList['spec/*_spec.rb']
	t.rcov = true
	t.rcov_opts = ['--exclude', 'examples']
end

task :default => :spec

######################################################

require 'rake/rdoctask'

Rake::RDocTask.new do |t|
	t.rdoc_dir = 'rdoc'
	t.title    = "rush, a Ruby replacement for bash+ssh"
	t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
	t.options << '--charset' << 'utf-8'
	t.rdoc_files.include('README.rdoc')
	t.rdoc_files.include('lib/rush.rb')
	t.rdoc_files.include('lib/rush/*.rb')
end

