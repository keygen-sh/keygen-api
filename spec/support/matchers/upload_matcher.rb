# frozen_string_literal: true

require 'aws-sdk-s3'

RSpec::Matchers.define :upload do |*expectations|
  supports_block_expectations

  uploads = []
  matches = []

  match do |block|
    allow_any_instance_of(Aws::S3::Client).to(
      receive(:put_object) do |**actual, &writer|
        expectations.each do |expected|
          if writer.present? && expected in body:, **rest
            io = StringIO.new
            io.set_encoding(Encoding::BINARY)

            writer.call(io)

            matches << true if io.string == body && actual >= rest
          else
            matches << true if actual >= expected
          end
        end

        uploads << actual
      end
    )

    block.call

    # FIXME(ezekg) should this compare sizes >=?
    expectations.empty? ? !uploads.empty? : matches.size == expectations.size
  end

  failure_message do
    "Expected block to upload files matching #{expected.inspect}, but it wasn't uploaded: #{uploads.inspect}"
  end

  failure_message_when_negated do
    "Expected block to not upload files matching #{expected.inspect}, but it was uploaded: #{uploads.inspect}"
  end
end
