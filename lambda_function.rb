require 'aws-sdk-s3'
require 'aws-xray-sdk/lambda'
require 'logger'
require 'zlib'

$s3 = Aws::S3::Client.new()

def lambda_handler(event:, context:)
  logger = Logger.new($stdout)

  # TODO: Check for a value.
  destination_bucket = ENV.fetch('DESTINATION_BUCKET', nil)
  logger.info("Destination bucket: #{destination_bucket}")

  extension = ENV.fetch('DESTINATION_EXTENSION', nil)

  # Get the object location.
  bucket = event['Records'][0]['s3']['bucket']['name']
  key = event['Records'][0]['s3']['object']['key']
  logger.info("bucket: #{bucket} key: #{key}")

  # CloudWatch Logs get double compressed, so we need to unzip the contents
  # twice.
  data = $s3.get_object(bucket: bucket, key: key)
  uncompressed = Zlib::GzipReader.new(Zlib::GzipReader.new(data.body))

  # Update the file extension before writing.
  destination = "#{File.dirname(key)}/#{File.basename(key, '.gz')}"
  destination += ".#{extension}" if extension
  logger.info("Destination key: #{destination}")

  $s3.put_object(bucket: destination_bucket, body: uncompressed.read,
                 key: destination)
end
