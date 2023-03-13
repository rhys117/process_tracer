module ProcessTracer::RailsControllers
  module Start
    def send_action(method, *args)
      res = super(method, *args)

      Rails.logger.info("\n\nLOGGING STARTING\n\n")
      ProcessTracer::RailsControllers.start_tracer

      res
    end
  end

  module Stop
    def sent!
      Rails.logger.info("\n\nLOGGING STOPPING\n\n")
      ProcessTracer::RailsControllers.stop_trace

      super
    end
  end

  def self.start_tracer
    @current_trace = ProcessTracer::Trace.new
    @current_trace.start
  end

  def self.stop_trace
    @current_trace.stop

    unless @current_trace.logging_pieces.empty?
      @current_trace.push_to_remote
    end
  end

  def self.current_trace
    @current_trace
  end
end
