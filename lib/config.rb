# frozen_string_literal: true

# Retrieve and validation lambda configuration.
class Config
  attr_reader :destination, :extension

  def initialize(destination:, extension:)
    @destination = destination
    @extension = extension

    validate_required
  end

  def self.from_env
    new(
      destination: ENV.fetch('DESTINATION_BUCKET', nil),
      extension: ENV.fetch('DESTINATION_EXTENSION', nil)
    )
  end

  private

  def validate_required
    raise 'Destination bucket is required.' unless @destination
  end
end
