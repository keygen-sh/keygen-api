# frozen_string_literal: true

require 'rubygems/package'

FactoryBot.define do
  factory :release_manifest, aliases: %i[manifest] do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    artifact    { build(:artifact, account:, environment:) }
    release     { artifact.release }
    content     { SecureRandom.bytes(128) }

    trait :gemspec do
      artifact { build(:artifact, :gem, account:, environment:) }
      content  {
        gem     = file_fixture('ping-1.0.0.gem').read
        gemspec = Gem::Package.new(gem).spec

        gemspec.to_yaml
      }
    end
  end
end
