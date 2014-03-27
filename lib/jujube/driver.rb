require_relative "job_loader"
require_relative "job_file_generator"
require 'optparse'
require 'ostruct'
require 'pathname'

module Jujube
  class Driver
    def self.run
      self.new.run
    end

    def initialize(loader = JobLoader.new, generator = JobFileGenerator.new)
      @loader = loader
      @generator = generator
    end

    def run(argv = ARGV)
      argv = adjusted_for_jruby(argv)
      options = handle_options(argv)
      jobs = @loader.load_jobs(*options.paths || Pathname.getwd)
      @generator.generate(jobs, options.output || Pathname.new("jobs.yml"))
    end

    private

    def handle_options(argv)
      options = OpenStruct.new

      OptionParser.new do |opts|
        opts.banner = "Usage: #{$PROGRAM_NAME} [options] paths..."

        opts.on('-o', '--output FILENAME', 'Specify output file (default = "jobs.yml")') do |file|
          options.output = Pathname.new(file)
        end

        opts.on('-h', '--help', "Display this screen") do
          puts opts
          exit
        end
      end.parse!(argv)

      options.paths = argv.map { |file| Pathname.new(file) } unless argv.empty?

      options
    end

    def adjusted_for_jruby(argv)
      # When running the acceptance tests under JRuby, an extra '{}' argument
      # is passed in ARGV.  We remove it here so that it doesn't affect the
      # rest of the program logic.
      #
      # See https://github.com/jruby/jruby/issues/1290
      argv.pop if argv.last == "{}"
      argv
    end
  end
end
