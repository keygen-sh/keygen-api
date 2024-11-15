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

    content_path   { Faker::File.file_name }
    content_type   { Faker::File.mime_type }
    content_digest { "sha256-#{Digest::SHA256.hexdigest(content)}" }
    content_length { content.size }
    content        { Random.bytes(128) }

    trait :gemspec do
      artifact     { build(:artifact, :gem, account:, environment:) }
      content_path { 'ping.gemspec' }
      content_type { 'application/x-yaml' }
      content      {
        gem     = file_fixture('ping-1.0.0.gem').read
        gemspec = Gem::Package.new(gem).spec

        gemspec.to_yaml
      }
    end

    trait :package_json do
      artifact       { build(:artifact, :npm_package, account:, environment:) }
      content_path   { 'package.json' }
      content_digest { "sha512-#{Digest::SHA512.hexdigest(content)}" }
      content_type   { 'application/vnd.npm.install-v1+json' }
      content        {
        tgz = file_fixture('hello-2.0.0.tgz').read
        tar = Zlib::GzipReader.new(tgz)
        pkg = Minitar::Reader.open tar do |archive|
          json = archive.find { _1.name in 'package/package.json' }
                        .read

          JSON.parse(json) # minify
              .to_json
        end

        pkg
      }
    end

    trait :index_json do
      artifact       { build(:artifact, :oci_image, account:, environment:) }
      content_path   { 'index.json' }
      content_digest { "sha256:#{Digest::SHA256.hexdigest(content)}" }
      content_type   { 'application/vnd.oci.image.index.v1+json' }
      content        {
        tar   = file_fixture('alpine-3.20.3.tar').read
        index = Minitar::Reader.open tar do |archive|
          json = archive.find { _1.name in 'index.json' }
                        .read

          JSON.parse(json) # minify
              .to_json
        end

        index
      }
    end

    trait :licensed do
      artifact { build(:artifact, :licensed, account:, environment:) }
    end

    trait :open do
      artifact { build(:artifact, :open, account:, environment:) }
    end

    trait :closed do
      artifact { build(:artifact, :closed, account:, environment:) }
    end

    trait :in_isolated_environment do
      environment { build(:environment, :isolated, account:) }
    end

    trait :isolated do
      in_isolated_environment
    end

    trait :in_shared_environment do
      environment { build(:environment, :shared, account:) }
    end

    trait :shared do
      in_shared_environment
    end

    trait :in_nil_environment do
      environment { nil }
    end

    trait :global do
      in_nil_environment
    end
  end
end
