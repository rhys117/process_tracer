require_relative 'process_tracer/version'
require_relative 'process_tracer/redis_service'
require_relative 'process_tracer/trace/helpers'
require_relative 'process_tracer/trace'
require_relative 'process_tracer/line_trace'
require_relative 'process_tracer/rails_tracing' if defined?(Rails)
require 'colorize'

module ProcessTracer
  def self.current_app
    @current_app ||= begin
      default = if defined?(Rails)
        Rails.application.class.module_parent_name
      else
        'app'
      end

      ENV.fetch("PROCESS_TRACER_APP_NAME", default)
    end
  end
end
