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

    trait :package_json do
      artifact { build(:artifact, :npm_package, account:, environment:) }
      content  {
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

    trait :manifest_json do
      artifact { build(:artifact, :docker_image, account:, environment:) }
      content  {
        tar      = file_fixture('alpine-3.20.3.tar').read
        manifest = Minitar::Reader.open tar do |archive|
          json = archive.find { _1.name in 'manifest.json' }
                        .read

          JSON.parse(json) # minify
              .to_json
        end

        manifest
      }
    end

    trait :index_json do
      artifact { build(:artifact, :docker_image, account:, environment:) }
      content  {
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
  end
end
