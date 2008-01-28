require 'yaml'

module Rush
	class Config
		attr_reader :dir

		def initialize(location=nil)
			@dir = Rush::Dir.new(location || "#{ENV['HOME']}/.rush")
			@dir.create
		end

		def history_file
			dir['history.yml']
		end

		def save_history(data)
			history_file.write YAML.dump(data)
		end

		def load_history
			history_file.exists? ? YAML.load(history_file.contents) : []
		end
	end
end
