# frozen_string_literal: true

require 'aws-sdk-s3'

RSpec::Matchers.define :upload do |*expectations|
  supports_block_expectations

  objects = []
  matches = []

  match do |block|
    allow_any_instance_of(Aws::S3::Client).to(
      receive(:put_object).and_wrap_original do |original, **object, &writer|
        objects << object

        expectations.each do |expected|

          if writer.present? && expected in body:, **rest
            matcher = RSpec::Matchers::BuiltIn::Include.new(rest)

            io = StringIO.new
            io.set_encoding(Encoding::BINARY)

            writer.call(io)

            matches << expected.hash if body === io.string && matcher.matches?(object)
          else
            matcher = RSpec::Matchers::BuiltIn::Include.new(expected)

            matches << expected.hash if matcher.matches?(object)
          end
        end

        original.call(**object, &writer)
      end
    )

    block.call

    # FIXME(ezekg) should this compare sizes >=?
    expectations.empty? ? !objects.empty? : expectations.all? { matches.include?(_1.hash) }
  end

  failure_message do
    "Expected block to upload #{expectations.size} objects matching #{expected.inspect}, but got: #{objects.inspect}"
  end

  failure_message_when_negated do
    "Expected block to not upload #{expectations.size} objects matching #{expected.inspect}, but got: #{objects.inspect}"
  end
end
