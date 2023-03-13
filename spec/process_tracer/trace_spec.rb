require 'spec_helper'

RSpec.describe ProcessTracer::Trace do
  let(:default_trace) { described_class.new { FakeService.run('test param') } }

  describe '#print' do
    it 'should be able to print result' do
      expect { default_trace.print }.to output(file_fixture('fake_service_output.txt')).to_stdout
    end
  end

  describe '#nested_pieces' do
    it 'should nest child pieces appropriately' do
      result = default_trace.nested_piece

      # First layer
      expect(result[:object].to_s).to include('FakeService')
      expect(result[:method]).to eq(:run)

      # Second layer
      child_pieces_name_method = result[:child_pieces].map { |piece| [piece[:object].to_s, piece[:method]] }
      expect(child_pieces_name_method).to eq(
        [
          ['#<Class:FakeService>', :first_own_method],
          ['#<Class:SingletonOperation>', :run],
          ['#<Class:FakeService>', :second_own_method],
          ['InstantiatedOperation', :initialize],
          ['InstantiatedOperation', :run]
        ]
      )

      # Third layer
      child_pieces_name_method = result[:child_pieces][1][:child_pieces].map { |piece| [piece[:object].to_s, piece[:method]] }
      expect(child_pieces_name_method).to eq(
        [
          ['#<Class:SingletonOperation>', :nested_method],
        ]
      )
    end
  end
end
