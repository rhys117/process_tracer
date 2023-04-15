module ProcessTracer::RailsTracing
  extend ActiveSupport::Concern

  included do
    prepend_around_action :trace
  end

  def trace(&block)
    raise 'Only to be used in development' unless Rails.env.development?

    # trace.tracer.enable
    ProcessTracer::LineTrace.new(&block).push_to_redis
  end
end
