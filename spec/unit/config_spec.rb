# frozen_string_literal: true

require 'config'

describe Config do
  describe '#validate_required' do
    let(:test) { config.send(:validate_required) }

    let(:config) do
      described_class.new(destination: 'test', extension: '').tap do |c|
        c.instance_variable_set(:@destination, destination)
      end
    end

    context 'when a destination bucket is supplied' do
      let(:destination) { 'test-bucket' }

      it 'does not raise an exception' do
        expect { test }.not_to raise_error
      end
    end

    context 'when a destination bucket is not supplied' do
      let(:destination) { nil }

      it 'raises an exception' do
        expect { test }.to raise_error(RuntimeError)
      end
    end
  end

  describe '.from_env' do
    let(:test) { described_class.from_env }

    context 'with all environment variables set' do
      before do
        stub_const('ENV', { 'DESTINATION_BUCKET' => 'test-bucket',
                            'DESTINATION_EXTENSION' => 'json' })
      end

      it 'uses the set destination' do
        expect(test.destination).to eq('test-bucket')
      end

      it 'uses the set extension' do
        expect(test.extension).to eq('json')
      end
    end

    context 'without all environment variables set' do
      before do
        stub_const('ENV', { 'DESTINATION_BUCKET' => 'test-bucket' })
      end

      it 'uses the set destination' do
        expect(test.destination).to eq('test-bucket')
      end

      it 'uses the default extension' do
        expect(test.extension).to eq(nil)
      end
    end
  end
end
