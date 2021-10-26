require 'ox'

class GenerateAppcastService < BaseService
  include Rails.application.routes.url_helpers

  def initialize(account:, releases:)
    @account  = account
    @releases = releases
  end

  def call
    builder = Ox::Builder.new

    builder.instruct(:xml, version: '1.0', encoding: 'UTF-8')
    builder.element(:rss,
      version: '2.0',
      'xmlns:sparkle': 'http://www.andymatuschak.org/xml-namespaces/sparkle',
      'xmlns:dc': 'http://purl.org/dc/elements/1.1/',
    )

    builder.element(:channel) do
      builder.element(:title) { builder.text("Releases for #{account.name}") }
      builder.element(:description) { builder.text('Most recent changes with links to upgrades.') }
      builder.element(:language) { builder.text('en') }

      available_releases.find_each do |release|
        product  = release.product
        artifact = release.artifact

        builder.element(:item) do
          builder.element(:title) { builder.text(release.name.to_s) }
          builder.element(:link) { builder.text(product.url.to_s) }
          builder.element(:'sparkle:version') { builder.text(release.version.to_s) }
          builder.element(:'sparkle:channel') { builder.text(release.channel.key) } if release.pre_release?
          # TODO(ezekg) Add support for serializing:
          #               - sparkle:minimumSystemVersion
          #               - sparkle:releaseNotesLink
          builder.element(:description) { builder.cdata(release.description.to_s) } if release.description?
          builder.element(:pubDate) { builder.text(release.created_at.httpdate) }
          builder.element(:enclosure,
            url: v1_account_product_artifact_path(account, product, artifact.key),
            'sparkle:edSignature': release.signature.to_s,
            length: release.filesize.to_s,
            type: 'application/octet-stream',
          )
        end
      end
    end

    builder.to_s
  end

  private

  attr_reader :account, :releases

  def available_releases
    releases.preload(:product)
            .for_filetype([:zip, :pkg, :dmg])
            .with_artifact
            .limit(100)
  end
end
