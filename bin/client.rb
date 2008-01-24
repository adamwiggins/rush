require File.dirname(__FILE__) + '/../lib/rush'

Rush::Box.new('localhost').execute_remote(:action => 'write', :full_path => '/tmp/mytest', :payload => 'something')

