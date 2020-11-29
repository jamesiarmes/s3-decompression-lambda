# frozen_string_literal: true

load "#{__dir__}/../vendor/bundle/bundler/setup.rb"

require 'aws-sdk-s3'
require 'aws-xray-sdk/lambda'
require 'logger'
require 'zlib'
require "#{__dir__}/../lib/config"
require "#{__dir__}/../lib/handler"

$handler = Handler.new(
  config: Config.from_env,
  logger: Logger.new($stdout),
  s3_client: Aws::S3::Client.new
)

def lambda_handler(event:, context:)
  $handler.handle(event: event, context: context)
end
