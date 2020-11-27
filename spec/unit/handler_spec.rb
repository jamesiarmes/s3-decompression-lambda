# frozen_string_literal: true

require 'aws-sdk-s3'
require 'handler'
require 'logger'
require 'config'

describe Handler do
  let(:logger) { instance_double(Logger) }
  let(:extension) { 'json' }
  let(:config) do
    instance_double(Config, destination: 'dest-bucket', extension: extension)
  end
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:event) do
    {
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
  end

  subject do
    described_class.new(config: config, logger: logger, s3_client: s3_client)
  end

  before(:each) do
    allow(logger).to receive(:info)
  end

  describe '#handle' do
    let(:object_data) do
      instance_double(Aws::S3::Types::GetObjectOutput,
                      body: StringIO.new('{"test":"value"}'))
    end

    before(:each) do
      allow(subject).to receive(:read_object)
        .and_return(object_data)
      allow(subject).to receive(:deflate)
      allow(subject).to receive(:write_object).and_return('bucket/key')
    end

    it 'returns the object written' do
      expect(subject.handle(event: event, context: nil)).to eq('bucket/key')
    end
  end

  describe '#deflate' do
    let(:data) { StringIO.new('{"test":"value"}') }
    let(:gzip) { instance_double(Zlib::GzipReader, read: data.read) }

    context 'file contents need to be decompressed once' do
      subject { super().send(:deflate, data) }

      before(:each) do
        allow(Zlib::GzipReader).to receive(:new).with(data).and_return(gzip)
        allow(Zlib::GzipReader).to receive(:new)
          .with(gzip).and_raise(Zlib::GzipFile::Error)
      end

      it 'attempts to decompress twice' do
        expect(Zlib::GzipReader).to receive(:new).twice

        subject
      end

      it 'returns the decompressed data' do
        expect(subject).to eq('{"test":"value"}')
      end
    end

    context 'file contents need to be decompressed twice' do
      let(:compressed) { StringIO.new('AAAABBBB') }

      subject { super().send(:deflate, compressed) }

      before(:each) do
        allow(Zlib::GzipReader).to receive(:new).with(compressed)
                                                .and_return(data)
        allow(Zlib::GzipReader).to receive(:new).with(data).and_return(gzip)
        allow(Zlib::GzipReader).to receive(:new)
          .with(gzip).and_raise(Zlib::GzipFile::Error)
      end

      it 'attempts to decompress three times' do
        expect(Zlib::GzipReader).to receive(:new).exactly(3).times

        subject
      end

      it 'returns the decompressed data' do
        expect(subject).to eq('{"test":"value"}')
      end
    end
  end

  describe '#read_object' do
    let(:file) { StringIO.new('AAAABBBB') }

    subject { super().send(:read_object, event) }

    before(:each) do
      allow(s3_client).to receive(:get_object)
        .with(bucket: 'test-bucket', key: 'prefix/file.gz')
        .and_return(file)
    end

    it 'returns the file stream' do
      expect(subject).to eq(file)
    end
  end

  describe '#write_object' do
    let(:data) { '{"test":"value"}' }

    subject { super().send(:write_object, event, data) }

    before(:each) do
      allow(s3_client).to receive(:put_object)
    end

    context 'an extension is provided' do
      it 'writes the object with the extension' do
        expect(s3_client).to receive(:put_object)
          .with(bucket: 'dest-bucket', body: data, key: 'prefix/file.json')

        subject
      end

      it 'returns the new bucket and object' do
        expect(subject).to eq('dest-bucket/prefix/file.json')
      end
    end

    context 'an extension is not provided' do
      let(:extension) { nil }

      it 'writes the object without a new extension' do
        expect(s3_client).to receive(:put_object)
          .with(bucket: 'dest-bucket', body: data, key: 'prefix/file')

        subject
      end

      it 'returns the new bucket and object' do
        expect(subject).to eq('dest-bucket/prefix/file')
      end
    end
  end
end
