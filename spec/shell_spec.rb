require_relative 'base'
require_relative '../lib/rush/shell'

describe Rush::Shell do
	before do
		@shell = Rush::Shell.new
	end

 it 'Complete constants' do
   expect(@shell.complete('Obj')).to eq(["Object", "ObjectSpace"])
   expect(@shell.complete('Rush::Sh')).to eq(["Rush::Shell"])
 end

 it 'Complete executables' do
   expect(@shell.complete('rub')).to include 'ruby'
 end

 it 'Complete global method names' do
   eval('def wakawaka; p "hi"; end', @shell.pure_binding)
   expect(@shell.complete('waka')).to eq ["wakawaka"]
 end

 it 'Complete method names' do
   # rbx has additional Rush.method_table, Rush.method_table=
   expect(@shell.complete('Rush.meth')).
     to include("Rush.method_part", "Rush.method_defined?", "Rush.methods", "Rush.method")
   expect(@shell.complete('Rush.methods.inc')).to include "Rush.methods.include?"
 end

 it 'Complete paths' do
   expect(@shell.complete('root["bin/ba')).to  eq ["root[\"bin/bash"]
   expect(@shell.complete('root[\'bin/ba')).to eq ["root['bin/bash"]
   expect(@shell.complete('root/"bin/ba')).to  eq ["root/\"bin/bash"]
   expect(@shell.complete('root/\'bin/ba')).to eq ["root/'bin/bash"]
 end
end
