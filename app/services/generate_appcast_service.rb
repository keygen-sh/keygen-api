class GenerateAppcastService < BaseService
  include Rails.application.routes.url_helpers

  def initialize(account:, releases:)
    @account  = account
    @releases = releases
  end

  def call
    items = []

    available_releases.find_each do |release|
      product  = release.product
      artifact = release.artifact

      # TODO(ezekg) Sanitize all interpolation
      items << <<~XML
        <item>
          <title>#{release.name}</title>
          <link>#{product.url}</link>
          <sparkle:version>#{release.version}</sparkle:version>
          <sparkle:channel>#{release.channel.key}</sparkle:channel>
          <description>
            <![CDATA[#{release.description}]]>
          </description>
          <pubDate>#{release.created_at.httpdate}</pubDate>
          <enclosure url="#{v1_account_product_artifact_path(account, product, artifact.key)}"
                     sparkle:edSignature="#{release.signature}"
                     length="#{release.filesize}"
                     type="application/octet-stream" />
        </item>
      XML
    end

    <<~XML.squish
      <?xml version="1.0" encoding="utf-8"?>
      <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
        <channel>
          <title>Releases for #{account.name}</title>
          <description>Most recent changes with links to upgrades.</description>
          <language>en</language>
          #{items.join('\n')}
        </channel>
      </rss>
    XML
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
