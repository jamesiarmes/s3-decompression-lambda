# frozen_string_literal: true

require 'aws-sdk-s3'
require 'aws-xray-sdk/lambda'
require 'logger'
require 'zlib'
require 'lib/config'
require 'lib/handler'

$handler = Handler.new(
  config: Config.from_env,
  logger: Logger.new($stdout),
  s3_client: Aws::S3::Client.new
)

def lambda_handler(event:, context:)
  $handler.handle(event: event, context: context)
end
