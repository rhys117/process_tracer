# frozen_string_literal: true

require 'pry'
require 'process_tracer'
require_relative 'dummy_app/fake_service'
require_relative 'helpers/file_helpers'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include FileHelpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Stub out colorize to make it easier to work with outputs
  class String
    def colorize(params)
      self
    end
  end
end
