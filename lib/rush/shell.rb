require 'coolline'
require 'coderay'
require 'pp'

# Rush::Shell is used to create an interactive shell.  It is invoked by the rush binary.
module Rush
  class Shell
    attr_accessor :suppress_output, :config, :history
    # Set up the user's environment, including a pure binding into which
    # env.rb and commands.rb are mixed.
    def initialize
      root = Rush::Dir.new('/')
      home = Rush::Dir.new(ENV['HOME']) if ENV['HOME']
      pwd = Rush::Dir.new(ENV['PWD']) if ENV['PWD']

      @config = Rush::Config.new

      @history = Coolline::History.new config.history_file.full_path

      @readline = Coolline.new do |c|
        c.transform_proc = proc { syntax_highlight c.line }
        c.completion_proc = proc { complete c.completed_word }
      end

      @box = Rush::Box.new
      @pure_binding = @box.instance_eval "binding"
      $last_res = nil

      eval config.load_env, @pure_binding

      commands = config.load_commands
      Rush::Dir.class_eval commands
      Array.class_eval commands

      # Multiline commands should be stored somewhere
      @multiline_cmd = ''
    end

    # Run a single command.
    def execute(cmd)
      res = eval(@multiline_cmd << "\n" << cmd, @pure_binding)
      $last_res = res
      eval("_ = $last_res", @pure_binding)
      @multiline_cmd = ''
      print_result res
    rescue SyntaxError => e
      unless e.message.include? 'unexpected end-of-input'
        @multiline_cmd = ''
        puts "Exception #{e.class} -> #{e.message}"
      end
      # Else it should be multiline command.
    rescue Rush::Exception => e
      puts "Exception #{e.class} -> #{e.message}"
      @multiline_cmd = ''
    rescue ::Exception => e
      puts "Exception #{e.class} -> #{e.message}"
      e.backtrace.each { |t| puts "\t#{::File.expand_path(t)}" }
      @multiline_cmd = ''
    end

    # Run the interactive shell using coolline.
    def run
      loop do
        prompt = self.class.prompt || "#{`whoami`.chomp} $ "
        cmd = @readline.readline prompt

        finish if cmd.nil? or cmd == 'exit'
        next if cmd.empty?
        @history << cmd
        execute cmd
      end
    end

    # Tune the prompt with
    #   Rush::Shell.prompt = 'hey there! > '
    class << self
      attr_accessor :prompt
    end

    # Save history to ~/.rush/history when the shell exists.
    def finish
      puts
      exit
    end

    # Nice printing of different return types, particularly Rush::SearchResults.
    def print_result(res)
      return if self.suppress_output
      if res.kind_of? String
        output = res
      elsif res.kind_of? Rush::SearchResults
        output = res.to_s <<
          "#{res.entries.size} matching files with #{res.lines.size} matching lines"
      elsif res.respond_to? :each
        pp res
      else
        output = "=> #{res.inspect}"
      end
      output.lines.count > 5 ? output.less : puts(output)
    end

    # Try to do tab completion on dir square brackets and slash accessors.
    #
    # Example:
    #
    # dir['subd  # presing tab here will produce dir['subdir/ if subdir exists
    # dir/'subd  # presing tab here will produce dir/'subdir/ if subdir exists
    #
    # This isn't that cool yet, because it can't do multiple levels of subdirs.
    # It does work remotely, though, which is pretty sweet.
    #
    # TODO:
    #   1. move to separate module
    #   2. agressive refactor it
    #
    def complete(input)
      receiver, accessor, *rest = path_parts(input)
      return [] unless receiver
      case accessor
      when /^[\[\/]$/ then complete_path(receiver, accessor, *rest)
      when /^\.$/     then complete_method(receiver, accessor, *rest)
      when nil        then complete_variable(receiver, *rest)
      else []
      end
    end

    # TODO: get string from space to last dot and do something sane with it.
    # I just don't want to figure out what's going on there.
    def path_parts(input)   # :nodoc:
      case input
      when /((?:@{1,2}|\$|)\w+(?:\[[^\]]+\])*)([\[\/])(['"])([^\3]*)$/
        $~.to_a.slice(1, 4).push($~.pre_match)
      when /((?:@{1,2}|\$|)\w+(?:\[[^\]]+\])*)(\.)(\w*)$/
        $~.to_a.slice(1, 3).push($~.pre_match)
      when /((?:@{1,2}|\$|)\w+)$/
        $~.to_a.slice(1, 1).push(nil).push($~.pre_match)
      else
        [ nil, nil, nil ]
      end
    end

    def complete_method(receiver, dot, partial_name, pre)
      path = eval("#{receiver}.full_path", @pure_binding) rescue nil
      box = eval("#{receiver}.box", @pure_binding) rescue nil
      return [] unless (path and box)
      box[path].methods. # why box[path] ?
        select { |e| e.match /^#{Regexp.escape(partial_name)}/ }.
        map    { |e| (pre || '') + receiver + dot + e.to_s }
    end

    def complete_path(possible_var, accessor, quote, partial_path, pre)   # :nodoc:
      original_var, fixed_path = possible_var, ''
      if /^(.+\/)([^\/]*)$/ === partial_path
        fixed_path, partial_path = $~.captures
        possible_var += "['#{fixed_path}']"
      end
      full_path = eval("#{possible_var}.full_path", @pure_binding) rescue nil
      box = eval("#{possible_var}.box", @pure_binding) rescue nil
      return [] unless (full_path and box)
      Rush::Dir.new(full_path, box).entries.
        select { |e| e.name.match(/^#{Regexp.escape(partial_path)}/) }.
        map    { |e| (pre || '') + original_var + accessor + quote +
          fixed_path + e.name + (e.dir? ? "/" : "") }
    end

    def complete_variable(partial_name, pre)
      pre = eval(pre, @pure_binding) rescue nil
      the_binding = pre ? pre.instance_eval('binding') : @pure_binding
      lvars = eval('local_variables', the_binding)
      gvars = eval('global_variables', the_binding)
      ivars = eval('instance_variables', the_binding)
      mets = eval('methods', the_binding) || eval('Kernel.methods')
      consts = eval('Object.constants', the_binding)
      (executables + lvars + gvars + ivars + mets + consts).
        select { |e| e.match(/^#{Regexp.escape(partial_name)}/) }.
        map    { |e| (pre || '') + e.to_s }
    end

    def executables
      ENV['PATH'].split(':').
        map { |x| Rush::Dir.new(x).entries.map(&:name) }.
        flatten
    end

    def syntax_highlight(input)
      CodeRay.encode input, :ruby, :term
    end
  end
end
