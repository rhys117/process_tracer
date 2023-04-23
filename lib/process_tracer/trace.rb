module ProcessTracer
  class Trace
    include ProcessTracer::Trace::Helpers

    attr_reader :logging_pieces, :result

    def initialize(mode: :own_defs, &blk)
      @logging_pieces = []
      @trace_depth = 0
      @start_time = Time.now
      @mode = mode
      @within_library_call = false # will flip true the first time it's checked

      @result = if blk
        tracer.enable do
          blk.call
        end
      end
    end

    def push_to_redis
      ProcessTracer::RedisService.append_pair(
        ProcessTracer.current_app, {
          started_at: @start_time,
          application: ProcessTracer.current_app,
          trace: nested_pieces
        }
      )
    end

    def print
      @logging_pieces.each_with_index do |piece, index|
        call_string = piece[:singleton_method_call] ? '.' : '#'

        call_string += "#{piece[:method]}:#{piece[:params]}"

        call_and_value = "#{call_string} > #{piece[:return_value].inspect}"
        if should_show_class_name?(piece, target_pieces: @logging_pieces[..index])
          puts "#{logging_indentation(piece[:depth])}#{piece[:readable_class]}#{call_and_value}".colorize(:yellow)
        else
          puts "#{logging_indentation(piece[:depth])}#{call_and_value}".colorize(:green)
        end
      end

      nil
    end

    def nested_pieces
      @nested_pieces ||= begin
        return if @logging_pieces.nil?

        pieces_copy = @logging_pieces.dup
        pieces_copy.each do |piece|
          piece[:child_pieces] = []
        end

        until pieces_copy.count <= 1
          add_next_child!(pieces_copy)
        end

        pieces_copy
      end
    end

    def within_library_call?
      @within_library_call
    end

    def tracer
      @tracer ||= TracePoint.new(:line, :return) do |trace|
        next unless trace.defined_class
        next if readable_class(trace.defined_class) == 'ProcessTracer::Trace'

        # Only filter for methods that you've defined in the rails application and first call to external libraries
        if @mode == :own_defs
          executing_project_defined_code = trace.path.include?(Rails.application.root.to_s)

          # TODO: remove the rails dependency here
          if @within_library_call && !executing_project_defined_code
            next
          end

          @within_library_call = !executing_project_defined_code
        end

        details = {
          object: trace.defined_class,
          readable_class: readable_class(trace.defined_class),
          singleton_method_call: trace.defined_class.singleton_class?,
          method: trace.callee_id,
          path: trace.path,
          params: nil,
          return_value: nil,
          return_value_set: false,
        }

        last_match = @logging_pieces.reverse.detect do |piece|
          piece.except(:lineno, :depth) == details
        end

        case trace.event
        when :line
          next if last_match.present? && last_match[:lineno] < trace.lineno

          @logging_pieces << details.merge(lineno: trace.lineno, depth: @trace_depth)
          add_depth if executing_project_defined_code
        when :return
          next unless last_match

          last_match.update(
            return_value: trace.return_value,
            return_value_set: true,
            params: determine_variables(trace)
          )
          reduce_depth if executing_project_defined_code
        end
      end
    end

    private

      def add_next_child!(pieces)
        deepest_depth = pieces.map { |piece| piece[:depth] }.max
        target_index = pieces.find_index { |piece| piece[:depth] == deepest_depth }
        pieces[target_index - 1][:child_pieces] << pieces.delete_at(target_index)
      end
  end
end
