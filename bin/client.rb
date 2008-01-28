require File.dirname(__FILE__) + '/../lib/rush'

Rush::Connection::Remote.new('localhost').transmit(:action => 'write', :full_path => '/tmp/mytest', :payload => 'something')

