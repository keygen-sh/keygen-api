# frozen_string_literal: true

module ChecksumHelper
  def checksum_for(artifact, delimiter: '-')
    case artifact.checksum&.size
    when 64
      "sha256#{delimiter}#{artifact.checksum}"
    when 128
      "sha512#{delimiter}#{artifact.checksum}"
    else
      nil
    end
  end
end