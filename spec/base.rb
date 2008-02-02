require 'rubygems'
require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'rush'

def mock_config(&block)
	sandbox_dir = "/tmp/fake_config.#{Process.pid}"
	config = Rush::Config.new(sandbox_dir)
	block.call(config)
	FileUtils.rm_rf(sandbox_dir)
end
