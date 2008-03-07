require 'rake'
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

require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'fileutils'
include FileUtils

version = "0.1"
name = "rush"

spec = Gem::Specification.new do |s|
	s.name = name
	s.version = version
	s.summary = "A Ruby replacement for bash+ssh."
	s.description = "A Ruby replacement for bash+ssh, providing both an interactive shell and a library.  Manage both local and remote unix systems from a single client."
	s.author = "Adam Wiggins"
	s.email = "adam@heroku.com"
	s.homepage = "http://rush.heroku.com/"
	s.executables = [ "rush", "rushd" ]
	s.rubyforge_project = "ruby-shell"

	s.add_dependency 'mongrel'
	s.add_dependency 'rspec'
	s.add_dependency 'session'

	s.platform = Gem::Platform::RUBY
	s.has_rdoc = true
	
	s.files = %w(Rakefile) + Dir.glob("{bin,lib,spec}/**/*")
	
	s.require_path = "lib"
	s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
	p.need_tar = true if RUBY_PLATFORM !~ /mswin/
end

task :install => [ :package ] do
	sh %{sudo gem install pkg/#{name}-#{version}.gem}
end

task :uninstall => [ :clean ] do
	sh %{sudo gem uninstall #{name}}
end

Rake::TestTask.new do |t|
	t.libs << "spec"
	t.test_files = FileList['spec/*_spec.rb']
	t.verbose = true
end

Rake::RDocTask.new do |t|
	t.rdoc_dir = 'doc'
	t.title    = "rush, a Ruby replacement for bash+ssh"
	t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
	t.options << '--charset' << 'utf-8'
	t.rdoc_files.include('README')
	t.rdoc_files.include('lib/rush.rb')
	t.rdoc_files.include('lib/rush/*.rb')
end

CLEAN.include [ 'pkg', '*.gem', '.config' ]

