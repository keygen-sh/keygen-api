# frozen_string_literal: true

require 'rubygems/package'
require 'minitar'
require 'zlib'

FactoryBot.define do
  factory :release_descriptor, aliases: %i[descriptor] do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    artifact    { build(:artifact, account:, environment:) }
    release     { artifact.release }

    content_type   { 'application/octet-stream' }
    content_length { rand(1.kilobyte..512.megabytes) }
    content_digest { Random.hex(32) }
  end
end
