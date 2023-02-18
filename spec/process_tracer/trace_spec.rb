require 'spec_helper'

RSpec.describe ProcessTracer::Trace do
  let(:default_trace) { described_class.new { FakeService.run('test param') } }

  it 'should be able to print result' do
    expect { default_trace.print }.to output(file_fixture('fake_service_output.txt')).to_stdout
  end
end
