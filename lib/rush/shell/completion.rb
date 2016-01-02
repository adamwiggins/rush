module Rush
  # Paths, executables and methods copmletion module.
  #
  module Completion
    # The complete method itself.
    # @param input [String] part of line from last space/beginning of line.
    # @returns [String] completed string.
    #
    # Types of completed lines:
    #   kernel constants, global variables, executables:
    #     CON<tab> -- constant;
    #     met<tab> -- method/variable name;
    #     execu<tab> -- executable file from PATH environment variable;
    #   given module/class constants:
    #     Object::CON<tab> -- constant of given module/class;
    #   methods:
    #     Object.met<tab> -- method of object;
    #     Object.method1.meth<tab>;
    #     variable.met<tab>;
    #     variable.method1.method2.met<tab> -- method number N in chain;
    #   paths:
    #     box['pa<tab. -- relative to box path;
    #     box['path/to/fi<tab> -- relative path with multiple lvls;
    #     box/'pa<tab> -- another syntax to relative path;
    #     box/'path/to/fi<tab> -- the same;
    #
    def complete(input)
      TEMPLATES.values
        .select { |x| x[:regexp].match input }
        .map    { |x| send x[:method], input }
        .flatten
        .compact
    end

    TEMPLATES = {
      constant: {
        regexp: /[A-Z](\w|_)+/,
        method: :complete_constant
      },
      object_constant: {
        regexp: /^([A-Z](\w|_)+::)+[A-Z](\w|_)+$/,
        method: :complete_object_constant
      },
      global_method: {
        regexp: /^[a-z](\w|_)+$/,
        method: :complete_global_method
      },
      method: {
        regexp: /^(((\w|_)+(\.|::))+)((\w|_)+)$/,
        method: :complete_method
      },
      path: {
        regexp: /^(\w|_|.|:| )+[\[\/][\'\"].*$/,
        method: :complete_path
      }
    }

    def complete_constant(input)
      Object.constants.map(&:to_s).select { |x| x.start_with? input }.sort
    end

    def complete_object_constant(input)
      receiver, delimiter, const_part = *input.rpartition('::')
      eval(receiver, pure_binding).constants
        .map(&:to_s)
        .select { |x| x.start_with? const_part }
        .map    { |x| receiver + delimiter + x }
    end

    def complete_global_method(input)
      complete_for(pure_binding, input)
    end

    def complete_method(input)
      receiver, delimiter, method_part = *input.rpartition('.')
      the_binding = eval(receiver, pure_binding).instance_eval('binding')
      complete_for(the_binding, method_part)
        .map { |x| receiver + delimiter + x }
    end

    def complete_for(the_binding, method_part)
      lvars = eval('local_variables', the_binding)
      gvars = eval('global_variables', the_binding)
      ivars = eval('instance_variables', the_binding)
      mets = eval('methods', the_binding)
      (executables + lvars + gvars + ivars + mets)
        .map(&:to_s)
        .select { |e| e.start_with? method_part }
    end

    def executables
      Rush::Path.executables
    end

    def complete_path(input)
      delimiters = %w([' [" /' /")
      delimiter = delimiters.find { |x| input.include? x }
      object, _, path = *input.rpartition(delimiter)
      path_done, _, path_part = path.rpartition('/')
      return [] unless eval(object, pure_binding).class == Rush::Dir
      box = eval(object + "/'" + path_done + "'", pure_binding)
      box.entries
        .map(&:name)
        .select { |x| x.start_with? path_part }
        .map { |x| object + delimiter + path_done + '/' + x }
    end
  end
end
