# frozen_string_literal: true

require 'config'

describe Config do
  describe '#validate_required' do
    let(:config) do
      Config.new(destination: 'test', extension: '').tap do |c|
        c.instance_variable_set(:@destination, destination)
      end
    end

    subject { config.send(:validate_required) }

    # before(:each) do
    #   allow(Config).to receive(:new).and_return(config)
    #   allow(config).to receive(:validate_required).and_call_original
    #   config.
    # end

    context 'a destination bucket is supplied' do
      let(:destination) { 'test-bucket' }

      it 'does not raise an exception' do
        expect { subject }.to_not raise_error
      end
    end

    context 'a destination bucket is not supplied' do
      let(:destination) { nil }

      it 'raises an exception' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  describe '.from_env' do
    subject { Config.from_env }

    context 'all environment variables are set' do
      before(:each) do
        stub_const('ENV', { 'DESTINATION_BUCKET' => 'test-bucket',
                            'DESTINATION_EXTENSION' => 'json' })
      end

      it 'uses the set destination' do
        expect(subject.destination).to eq('test-bucket')
      end

      it 'uses the set extension' do
        expect(subject.extension).to eq('json')
      end
    end

    context 'not all environment variables are set' do
      before(:each) do
        stub_const('ENV', { 'DESTINATION_BUCKET' => 'test-bucket' })
      end

      it 'uses the set destination' do
        expect(subject.destination).to eq('test-bucket')
      end

      it 'uses the default extension' do
        expect(subject.extension).to eq(nil)
      end
    end
  end
end
