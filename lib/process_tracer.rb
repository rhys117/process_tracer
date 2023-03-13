require_relative 'process_tracer/version'
require_relative 'process_tracer/trace'
require_relative 'process_tracer/rails_controllers'
require_relative 'process_tracer/delivery'
require 'colorize'

module ProcessTracer
  def self.enable_rails_controller_tracing!
    ActionController::BasicImplicitRender.prepend ProcessTracer::RailsControllers::Start
    ActionDispatch::Response.prepend ProcessTracer::RailsControllers::Stop
  end
end
