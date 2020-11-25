require 'logger'
require 'json'
# require 'aws-sdk-lambda'
require 'aws-sdk-s3'
require 'zlib'
require 'stringio'

# $client = Aws::Lambda::Client.new()
# $client.get_account_settings()
$s3 = Aws::S3::Client.new()

require 'aws-xray-sdk/lambda'

def lambda_handler(event:, context:)
  logger = Logger.new($stdout)
  # logger.info('## ENVIRONMENT VARIABLES')
  # vars = Hash.new
  # ENV.each do |variable|
  #   vars[variable[0]] = variable[1]
  # end
  # logger.info(vars.to_json)
  # logger.info('## EVENT')
  # logger.info(event.to_json)
  # logger.info('## CONTEXT')
  # logger.info(context)
  # $client.get_account_settings().account_usage.to_h

  bucket = event['Records'][0]['s3']['bucket']['name']
  key = event['Records'][0]['s3']['object']['key']
  logger.info("bucket: #{bucket} key: #{key}")

  obj = $s3.get_object(bucket: bucket, key: key)
  uncompressed = Zlib::GzipReader.new(Zlib::GzipReader.new(obj.body))

  destination = "#{File.dirname(key)}/#{File.basename(key, '.gz')}"
  logger.info("Destination key: #{destination}")

  $s3.put_object(bucket: 'armesnet', body: uncompressed.read, key: destination)
end
