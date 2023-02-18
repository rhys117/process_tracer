require_relative 'trace/helpers'

module ProcessTracer
  class Trace
    include Helpers

    IGNORE_LIST = {
      'Kernel' => [:class, :require, :zeitwerk_original_require],
      'WeakRef' => :all,
      'Delegator' => :all,
      'Zeitwerk' => :all,
      'Bootsnap' => :all,
      'DEBUGGER__' => :all,
      'Module' => :all,
      'ActiveRecord::ConnectionAdapters::ConnectionPool' => :all,
      'MonitorMixin' => :all,
      'BasicObject' => [:singleton_method_added],
    }.freeze

    def initialize(&blk)
      @logging_pieces = []
      @trace_depth = 0
      @start_time = Time.now

      run(&blk)
    end

    def push_to_remote(&blk)
      tracer.enable do
        blk.call
      end

      Delivery.push(@start_time, @logging_pieces)
    end

    def print
      @logging_pieces.each_with_index do |piece, index|
        class_string = readable_class(piece[:object])

        class_method = piece[:object].singleton_class?
        call_string = class_method ? '.' : '#'

        call_string += "#{piece[:method]}:#{piece[:params]}"

        call_and_value = "#{call_string} > #{piece[:return_value].inspect}"
        if should_show_class_name?(piece, target_pieces: @logging_pieces[..index], class_string:)
          puts "#{logging_indentation(piece[:depth])}#{class_string}#{call_and_value}".colorize(:yellow)
        else
          puts "#{logging_indentation(piece[:depth])}#{call_and_value}".colorize(:green)
        end
      end

      nil
    end

    def nested_pieces
      @nested_pieces ||= begin
        pieces_copy = @logging_pieces.dup

        until pieces_copy.count == 1
          add_next_child!(pieces_copy)
        end

        pieces_copy.first
      end
    end

    def add_next_child!(pieces)
      deepest_depth = pieces.map { |piece| piece[:depth] }.max
      target_index = pieces.find_index { |piece| piece[:depth] == deepest_depth }
      pieces[target_index - 1][:child_pieces] << pieces.delete_at(target_index)
    end

    private

      def run(&blk)
        res = nil

        self.tracer.enable do
          res = blk.call
        end

        res
      end

      def tracer
        @tracer ||= TracePoint.new(:call, :return) do |trace|
          next if should_ignore_call?(trace)

          case trace.event
          when :call
            if @logging_pieces.any? && @logging_pieces.last(2).map { |piece| piece[:object] }.uniq != 1
              add_depth
            end

            @logging_pieces << {
              object: trace.defined_class,
              params: determine_variables(trace),
              method: trace.callee_id,
              return_value: nil,
              return_value_set: false,
              depth: @trace_depth,
              child_pieces: []
            }

            if @logging_pieces.any? && @logging_pieces.last[:object] != trace.defined_class
              add_depth
            end
          when :return
            target = @logging_pieces.reverse_each.detect { |piece| !piece[:return_value_set] }

            if target
              target.update(
                return_value: trace.return_value,
                return_value_set: true
              )

              reduce_depth
            else
              {}
            end
          end
        end
      end
    end
end
