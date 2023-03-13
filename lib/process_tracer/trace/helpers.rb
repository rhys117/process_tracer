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

        def should_show_class_name?(current_piece, target_pieces:)
          return true if current_piece[:depth] < 1

          last_indentation = target_pieces.reverse.detect { |piece| piece[:depth] == current_piece[:depth] - 1 }
          last_indentation_readable_class = readable_class(last_indentation[:object])

          current_piece[:readable_class] != last_indentation_readable_class
        end

        def determine_variables(trace)
          readable_params = trace.parameters.flatten & trace.binding.local_variables.flatten
          readable_params.map do |n|
            [n, trace.binding.local_variable_get(n)]
          end.to_h
        end

        def should_ignore_call?(trace)
          if readable_class(trace.defined_class) == 'ActionController::BasicImplicitRender'
            @basic_implicit_render_observed = true
          end
          return true unless @basic_implicit_render_observed

          match = IGNORE_LIST.keys.detect { |key| readable_class(trace.defined_class).match(/^#{key}.*/) }
          return false unless match

          ignore_methods = IGNORE_LIST[match]
          ignore_methods == :all || ignore_methods.include?(trace.callee_id)
        end
    end
  end
end
