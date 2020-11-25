# frozen_string_literal: true

# Lambda execution handler.
class Handler
  def initialize(config:, logger:, s3_client:)
    @config = config
    @logger = logger
    @s3 = s3_client
  end

  # Handles an individual execution
  def handle(event:, context:) # rubocop:disable Lint/UnusedMethodArgument
    @logger.info("Destination bucket: #{@config.destination}")
    write_object(event, deflate(read_object(event).body))
  end

  private

  # Decompresses the data.
  #
  # Will continue to decompress until failure, as some data sources such as
  # CloudWatch Logs -> Kinesis could be compressed twice.
  def deflate(stream)
    data = Zlib::GzipReader.new(stream)
    deflate(data)
  rescue Zlib::GzipFile::Error
    stream.read
  end

  # Reads an S3 object from the source.
  def read_object(event)
    # Get the object location.
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    @logger.info("bucket: #{bucket} key: #{key}")

    @s3.get_object(bucket: bucket, key: key)
  end

  # Writes an S3 object to the destination.
  def write_object(event, data)
    source_key = event['Records'][0]['s3']['object']['key']
    key = "#{File.dirname(source_key)}/#{File.basename(source_key, '.gz')}"
    key += ".#{@config.extension}" if @config.extension
    @logger.info("Destination key: #{key}")

    @s3.put_object(bucket: @config.destination, body: data, key: key)

    "#{@config.destination}/#{key}"
  end
end
