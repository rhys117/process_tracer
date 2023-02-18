module ProcessTracer
  class Trace
    module Helpers
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
    end

    def readable_class(clazz)
      clazz.to_s.gsub('#<Class:', '').gsub('>', '').gsub('.', '')
    end
  end
end