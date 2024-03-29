# frozen_string_literal: true

require_relative 'lib/process_tracer/version'

Gem::Specification.new do |spec|
  spec.name = 'process_tracer'
  spec.version = ProcessTracer::VERSION
  spec.authors = ['Rhys Murray']
  spec.email = ['contact@rhysmurray.me']

  spec.summary = 'Trace your method calls.'
  spec.description = 'Traces your method calls and gives clear determination of what methods and '\
    'arguments are being passed down the chain.'
  spec.homepage = 'https://github.com/rhys117/process_tracer'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(/\A(?:(?:bin|test|spec|features)\/|\.(?:git|circleci)|appveyor)/)
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(/\Aexe\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_dependency 'colorize', '~> 0.8'
  spec.add_dependency 'redis'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
