# frozen_string_literal: true

module ChecksumHelper
  # see: https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity
  #      https://peps.python.org/pep-0503/
  def checksum_for(artifact, format: :sri)
    case [artifact.checksum_encoding, artifact.checksum_algorithm]
    in [:hex, :md5 | :sha1 | :sha224 | :sha256 | :sha384 | :sha512 => algorithm] if format == :pep
      "#{algorithm}=#{artifact.checksum}"
    in [:base64, :sha256 | :sha384 | :sha512 => algorithm] if format == :sri
      "#{algorithm}-#{artifact.checksum}"
    in [*] if format.nil?
      artifact.checksum
    else
      nil
    end
  end
end
