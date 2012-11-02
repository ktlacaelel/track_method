require 'fileutils'
require 'logger'
require 'cobalt'
require 'wrap_method'

module TrackMethod

  def self.configuration=(configuration)
    @configuration = configuration
  end

  def self.console
    return @console if @console
    @configuration ||= {}
    log_path = @configuration[:log_path] || 'log/track.log'
    FileUtils.mkdir_p File.dirname(log_path)
    logger = Logger.new(log_path)
    logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
    @console = Cobalt::Console.new :loggers => [logger]
  end

end

class Module
  def track_method(method_name, method_arguments = {})
    TrackMethod.console.notice "Tracking: #{self.name}.#{method_name}"
    wrap_method(method_name) do |org_method, args, block|
      benchmark_start = Time.now
      result = org_method.call(*args, &block)
      benchmark_end = Time.now

      # TODO: Code below should go somewhere else.
      benchmark_at = ((benchmark_end.to_f * 1000.0) - (benchmark_start.to_f * 1000.0))

      argument_mapping = {}
      method_arguments.each do |method_label, method_needle|
        argument_mapping[:method_label] = args[method_needle]
      end

      benchmark_output = "#{(benchmark_at).to_s.rjust(20, ' ')} #{self.name}.#{method_name}(#{argument_mapping.inspect})"

      case
      when benchmark_at > 500
        TrackMethod.console.error benchmark_output
      when benchmark_at > 200
        TrackMethod.console.warn benchmark_output
      when benchmark_at > 100
        TrackMethod.console.notice benchmark_output
      else
        TrackMethod.console.log benchmark_output
      end
      result
    end
  end
end

