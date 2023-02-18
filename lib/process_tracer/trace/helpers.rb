module ProcessTracer
  class Trace
    module Helpers
      private

        def add_depth
          @trace_depth += 1
        end

        def reduce_depth
          return unless @trace_depth

          @trace_depth -= 1
        end

        def logging_indentation(depth)
          running_ident = ''
          running_ident << '  ' * (depth || 0).abs

          running_ident
        end

        def readable_class(clazz)
          clazz.to_s.gsub('#<Class:', '').gsub('>', '').gsub('.', '')
        end

        def should_show_class_name?(current_piece, target_pieces:, class_string:)
          return true if current_piece[:depth] < 1

          last_indentation = target_pieces.reverse.detect { |piece| piece[:depth] == current_piece[:depth] - 1 }
          last_indentation_readable_class = readable_class(last_indentation[:object])

          class_string != last_indentation_readable_class
        end
    end
  end
end