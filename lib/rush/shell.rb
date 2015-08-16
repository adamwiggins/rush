require_relative 'shell/completion'
require 'coolline'
require 'coderay'
require 'pp'

module Rush
  # Rush::Shell is used to create an interactive shell.
  # It is invoked by the rush binary.
  #
  class Shell
    include Rush::Completion

    attr_accessor :suppress_output, :config, :history, :pure_binding
    # Set up the user's environment, including a pure binding into which
    # env.rb and commands.rb are mixed.
    def initialize
      root = Rush::Dir.new('/')
      home = Rush::Dir.new(ENV['HOME']) if ENV['HOME']
      pwd = Rush::Dir.new(ENV['PWD']) if ENV['PWD']

      @config = Rush::Config.new
      @box = Rush::Box.new
      @pure_binding = @box.instance_eval 'binding'
      $last_res = nil
      load_custom_commands
      set_readline
      @multiline_cmd = '' # Multiline commands should be stored somewhere
      $last_backtrace = '' # Backtrace should too.
    end

    def set_readline
      @history = Coolline::History.new config.history_file.full_path
      Coolline::Settings[:word_boundaries] = [' ', "\t"]
      Coolline::Settings[:completion_word_boundaries] = [' ', "\t"]
      @readline = Coolline.new do |c|
        c.transform_proc  = proc { syntax_highlight c.line }
        c.completion_proc = proc { complete c.completed_word }
      end
    end

    def load_custom_commands
      eval config.load_env, @pure_binding
      commands = config.load_commands
      Rush::Dir.class_eval commands
      Rush::File.class_eval commands
      Array.class_eval     commands
    end

    # Run the interactive shell using coolline.
    def run
      loop do
        prompt = self.class.prompt || "#{`whoami`.chomp} $ "
        cmd = @readline.readline prompt
        finish if cmd.nil? || cmd == 'exit'
        next   if cmd.empty?
        @history << cmd
        execute cmd
      end
    end

    # Run a single command.
    def execute(cmd)
      res = eval(@multiline_cmd << "\n" << cmd, @pure_binding)
      $last_res = res
      eval('_ = $last_res', @pure_binding)
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
      $last_backtrace = e.backtrace
        .map { |t| "\t#{::File.expand_path(t)}" }
        .join("\n")
      @multiline_cmd = ''
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
    #
    def print_result(res)
      return if suppress_output
      if res.is_a? String
        output = res
      elsif res.is_a? Rush::SearchResults
        output = res.to_s <<
          "#{res.entries.size} matching files with #{res.lines.size} lines"
      elsif res.respond_to? :each
        output = res.pretty_inspect
      else
        output = "   = #{res.inspect}"
      end
      output.lines.count > 5 ? output.less : puts(output)
    end

    # Syntax highlighting with coderay.
    #
    def syntax_highlight(input)
      CodeRay.encode input, :ruby, :term
    end
  end
end
