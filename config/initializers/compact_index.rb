# frozen_string_literal: true

require 'compact_index'

module CompactIndex::Ext
  # variant of CompactIndex::VersionsFile that's stored in-memory instead of the file-system
  class VersionsFile
    attr_reader :created_at, :io

    def initialize(gems)
      @created_at = Time.current.iso8601
      @io         = StringIO.new

      create(gems)
    end

    # the public interface expected by CompactIndex
    def contents(*, **) = io.tap(&:rewind).read

    private

    def create(gems)
      io.write "created_at: #{created_at}\n---\n"

      return if
        gems.empty?

      gems.each do |gem|
        next if
          gem.versions.empty?

        versions = gem.versions.map(&:number_and_platform).join(",")
        checksum = Digest::MD5.hexdigest(
          CompactIndex.info(gem.versions),
        )

        io.write "#{gem.name} #{versions} #{checksum}\n"
      end
    end
  end
end
