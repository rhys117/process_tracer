module ProcessTracer::RailsTracing
  extend ActiveSupport::Concern

  included do
    prepend_around_action :trace
  end

  def trace(&block)
    raise 'Only intended to be used in development due to performance drawbacks.' unless Rails.env.development?

    ProcessTracer::Trace.new(&block).push_to_redis
  end
end
