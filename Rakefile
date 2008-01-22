require 'rake'
require 'spec/rake/spectask'

desc "Run all specs"
Spec::Rake::SpecTask.new('specs') do |t|
	  t.spec_files = FileList['specs/*.rb']
end

task :default => :specs
