# frozen_string_literal: true

require 'aws-sdk-s3'
require 'handler'
require 'logger'
require 'config'

describe Handler do
  let(:test) do
    logger = instance_double(Logger)
    allow(logger).to receive(:info)

    described_class.new(
      config: instance_double(Config, destination: 'dest-bucket',
                                      extension: extension),
      logger: logger, s3_client: s3_client
    )
  end
  let(:extension) { 'json' }
  let(:s3_client) { instance_double(Aws::S3::Client) }

  event = {
    'Records' => [{
      's3' => {
        'bucket' => {
          'name' => 'test-bucket'
        },
        'object' => {
          'key' => 'prefix/file.gz'
        }
      }
    }]
  }

  describe '#handle' do
    let(:object_data) do
      instance_double(Aws::S3::Types::GetObjectOutput,
                      body: StringIO.new('{"test":"value"}'))
    end

    before do
      allow(test).to receive(:read_object)
        .and_return(object_data)
      allow(test).to receive(:deflate)
      allow(test).to receive(:write_object).and_return('bucket/key')
    end

    it 'returns the object written' do
      expect(test.handle(event: event, context: nil)).to eq('bucket/key')
    end
  end

  describe '#deflate' do
    let(:test) { super().send(:deflate, data) }
    let(:data) { StringIO.new('{"test":"value"}') }
    let(:gzip) { instance_double(Zlib::GzipReader, read: data.read) }

    context 'when file contents need to be decompressed once' do
      before do
        allow(Zlib::GzipReader).to receive(:new).with(data).and_return(gzip)
        allow(Zlib::GzipReader).to receive(:new)
          .with(gzip).and_raise(Zlib::GzipFile::Error)
      end

      it 'attempts to decompress twice' do
        test

        expect(Zlib::GzipReader).to have_received(:new).twice
      end

      it 'returns the decompressed data' do
        expect(test).to eq('{"test":"value"}')
      end
    end

    context 'when file contents need to be decompressed twice' do
      before do
        compressed = StringIO.new('AAAABBBB')

        allow(Zlib::GzipReader).to receive(:new)
          .with(data).and_return(compressed)
        allow(Zlib::GzipReader).to receive(:new)
          .with(compressed).and_return(gzip)
        allow(Zlib::GzipReader).to receive(:new)
          .with(gzip).and_raise(Zlib::GzipFile::Error)
      end

      it 'attempts to decompress three times' do
        test

        expect(Zlib::GzipReader).to have_received(:new).exactly(3).times
      end

      it 'returns the decompressed data' do
        expect(test).to eq('{"test":"value"}')
      end
    end
  end

  describe '#read_object' do
    let(:test) { super().send(:read_object, event) }
    let(:file) { StringIO.new('AAAABBBB') }

    before do
      allow(s3_client).to receive(:get_object)
        .with(bucket: 'test-bucket', key: 'prefix/file.gz')
        .and_return(file)
    end

    it 'returns the file stream' do
      expect(test).to eq(file)
    end
  end

  describe '#write_object' do
    let(:test) { super().send(:write_object, event, data) }
    let(:data) { '{"test":"value"}' }

    before do
      allow(s3_client).to receive(:put_object)
    end

    context 'with an extension' do
      it 'writes the object with the extension' do
        test

        expect(s3_client).to have_received(:put_object)
          .with(bucket: 'dest-bucket', body: data, key: 'prefix/file.json')
      end

      it 'returns the new bucket and object' do
        expect(test).to eq('dest-bucket/prefix/file.json')
      end
    end

    context 'without an extension provided' do
      let(:extension) { nil }

      it 'writes the object without a new extension' do
        test

        expect(s3_client).to have_received(:put_object)
          .with(bucket: 'dest-bucket', body: data, key: 'prefix/file')
      end

      it 'returns the new bucket and object' do
        expect(test).to eq('dest-bucket/prefix/file')
      end
    end
  end
end
