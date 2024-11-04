# frozen_string_literal: true

require 'rubygems/package'
require 'minitar'
require 'zlib'

FactoryBot.define do
  factory :release_manifest, aliases: %i[manifest] do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    artifact    { build(:artifact, account:, environment:) }
    release     { artifact.release }
    content     { Random.bytes(128) }

    trait :gemspec do
      artifact { build(:artifact, :gem, account:, environment:) }
      content  {
        gem     = file_fixture('ping-1.0.0.gem').read
        gemspec = Gem::Package.new(gem).spec

        gemspec.to_yaml
      }
    end

    trait :npm do
      artifact { build(:artifact, :npm_package, account:, environment:) }
      content  {
        tgz = file_fixture('hello-2.0.0.tgz').read
        tar = Zlib::GzipReader.new(tgz)
        pkg = Minitar::Reader.open tar do |archive|
          archive.find { _1.name in 'package/package.json' }
                 .read
        end

        pkg
      }
    end
  end
end
