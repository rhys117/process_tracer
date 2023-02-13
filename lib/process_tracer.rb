require_relative "process_tracer/version"
require 'colorize'

module ProcessTracer
  @tracing_methods = []

  def self.run(&blk)
    Private.reset_depth
    @logging_pieces = []

    res = nil

    tracer.enable do
      res = blk.call
    end

    @logging_pieces.each_with_index do |pieces, index|
      readable_class = pieces[:object].to_s.gsub("#<Class:", '').gsub(">", '').gsub('.', '')
      object_first_call = if pieces[:depth] < 1
        true
      else
        last_indentation = @logging_pieces[..index].reverse.detect { |piece| piece[:depth] == pieces[:depth] -1 }
        last_indentation_readable_class = last_indentation[:object].to_s.gsub("#<Class:", '').gsub(">", '').gsub('.', '')
        readable_class != last_indentation_readable_class
      end

      class_method = pieces[:object].singleton_class?
      call_string = class_method ? '.' : '#'

      call_string += "#{pieces[:method]}:#{pieces[:params]}"

      call_and_value = "#{call_string} > #{pieces[:return_value].inspect}"
      if object_first_call
        puts "#{Private.logging_indentation(pieces[:depth])}#{readable_class}#{call_and_value}".colorize(:yellow)
      else
        puts "#{Private.logging_indentation(pieces[:depth])}#{call_and_value}".colorize(:green)
      end
    end

    res
  end

  def self.add_tracer_target(key)
    @tracing_methods << key
  end

  def self.tracer
    @tracer ||= TracePoint.new(:call, :return) do |trace|
      next if Private.targeted_mode? && !@tracing_methods.include?(
        Private.method_owner_and_name_to_key(
          trace.defined_class, trace.callee_id
        )
      )

      ignore = {
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
      }

      readable_class = trace.defined_class.to_s.gsub("#<Class:", '').gsub(">", '').gsub('.', '')
      if (match = ignore.keys.detect { |key| readable_class.match(/^#{key}.*/) })
        ignore_methods = ignore[match]

        next if ignore_methods == :all || ignore_methods.include?(trace.callee_id)
      end

      case trace.event
      when :call
        readable_params = trace.parameters.flatten & trace.binding.local_variables.flatten
        params = readable_params.map { |n|
          [n, trace.binding.local_variable_get(n)]
        }.to_h

        # Always indent first child method call
        if @logging_pieces.any? && @logging_pieces.last(2).map { |piece| piece[:object] }.uniq != 1
          Private.add_depth
        end

        #if @logging_pieces.empty?
        @logging_pieces << {
          object: trace.defined_class,
          params: params,
          method: trace.callee_id,
          return_value: nil,
          return_value_set: false, # We could have methods return nil so track this by itself
          depth: Private.trace_depth,
          # include_class: include_class,
          child_pieces: []
        }

        if @logging_pieces.any? && @logging_pieces.last[:object] != trace.defined_class
          Private.add_depth
        end
      when :return
        target = @logging_pieces.reverse_each.detect { |piece| !piece[:return_value_set] }

        if target
          target.update(
            return_value: trace.return_value,
            return_value_set: true
          )

          Private.reduce_depth
        else
          {}
        end
      end
    end
  end

  class Private
    def self.on_method_added(klass, name, singleton_method: false)
      overwrite_class_target = singleton_method ? klass.singleton_class : klass
      key = method_owner_and_name_to_key(overwrite_class_target, name)

      Trace.add_tracer_target(key)
    end

    def self.method_owner_and_name_to_key(klass, name)
      "#{klass.object_id}##{name}"
    end

    def self.add_depth
      @trace_depth ||= 0
      @trace_depth += 1
    end

    def self.reduce_depth
      return unless @trace_depth

      @trace_depth -= 1
    end

    def self.reset_depth
      @trace_depth = 0
    end

    def self.trace_depth
      @trace_depth
    end

    def self.logging_indentation(depth)
      running_ident = ''
      running_ident << '  ' * ((depth || 0).abs)

      running_ident
    end

    def self.mode
      if ENV['TARGETED_TRACING'] == true
        :targeted
      else
        :all
      end
    end

    def self.targeted_mode?
      mode == :targeted
    end
  end

  module MethodHooks
    def method_added(name)
      super(name)

      Private.on_method_added(self, name)
    end

    def singleton_method_added(name)
      super(name)
      Private.on_method_added(self, name, singleton_method: true)
    end
  end
end
