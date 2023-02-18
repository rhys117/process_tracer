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
      @logging_pieces.each_with_index do |pieces, index|
        class_string = readable_class(pieces[:object])
        object_first_call = if pieces[:depth] < 1
          true
        else
          last_indentation = @logging_pieces[..index].reverse.detect { |piece| piece[:depth] == pieces[:depth] - 1 }
          last_indentation_readable_class = last_indentation[:object].to_s.gsub('#<Class:', '').gsub('>', '').
            gsub('.', '')
          class_string != last_indentation_readable_class
        end

        class_method = pieces[:object].singleton_class?
        call_string = class_method ? '.' : '#'

        call_string += "#{pieces[:method]}:#{pieces[:params]}"

        call_and_value = "#{call_string} > #{pieces[:return_value].inspect}"
        if object_first_call
          puts "#{logging_indentation(pieces[:depth])}#{class_string}#{call_and_value}".colorize(:yellow)
        else
          puts "#{logging_indentation(pieces[:depth])}#{call_and_value}".colorize(:green)
        end
      end

      nil
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
          if (match = IGNORE_LIST.keys.detect { |key| readable_class(trace.defined_class).match(/^#{key}.*/) })
            ignore_methods = IGNORE_LIST[match]

            next if ignore_methods == :all || ignore_methods.include?(trace.callee_id)
          end

          case trace.event
          when :call
            readable_params = trace.parameters.flatten & trace.binding.local_variables.flatten
            params = readable_params.map do |n|
              [n, trace.binding.local_variable_get(n)]
            end.to_h

            # Always indent first child method call
            if @logging_pieces.any? && @logging_pieces.last(2).map { |piece| piece[:object] }.uniq != 1
              add_depth
            end

            @logging_pieces << {
              object: trace.defined_class,
              params:,
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