# ProcessTracer

Leverage ruby's TracePoint class to see the exactly what code path your execution is taking.

Inspired by [trailblazers](https://github.com/trailblazer/trailblazer) `wtf?` method.

TODO:
- Work out how to handle rails/gem calls so first callout shows

## Usage
```ruby
trace = ProcessTracer::Trace.new { Task.perform(test: 'params') }
trace.print
# Task.perform:{:test=>"params"} > "Return value example"
#   .other_task_method:{} > "Other task method return value"
#   OtherClass.new:{} > "..."
#     .other_class_method:{} > "..."
```
