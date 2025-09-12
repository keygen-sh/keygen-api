class SignatureHelper
  class InvalidSignatureHeaderError < StandardError; end

  SIGNATURE_RE = %r{
    \A
    (keyid="(?<keyid>[^"]+)")?
    (\s*,\s*)
    (algorithm="(?<algorithm>[^"]+)")
    (\s*,\s*)
    (signature="(?<signature>[^"]+)")
    (\s*,\s*)
    (headers="(?<headers>[^"]+)")
    (\s*;\s*)?
    \z
  }xi

  def self.parse(signature_header)
    attrs = SIGNATURE_RE.match(signature_header)
    raise InvalidSignatureHeaderError, 'invalid signature header' if
      attrs.nil?

    keyid     = attrs[:keyid]
    algorithm = attrs[:algorithm]
    signature = attrs[:signature]
    headers   = attrs[:headers].split(' ')

    {
      keyid: keyid,
      algorithm: algorithm,
      signature: signature,
      headers: headers,
    }
  end

  def self.verify(account:, method:, host:, uri:, body:, signature_algorithm:, signature_header:, digest_header:, date_header:)
    sig_attrs = self.parse(signature_header)

    return false if
      sig_attrs[:keyid].present? && sig_attrs[:keyid] != account.id

    return false if
      sig_attrs[:algorithm] != signature_algorithm

    return false if
      !sig_attrs[:signature].present?

    sig_bytes    = Base64.strict_decode64(sig_attrs[:signature])
    sha256       = OpenSSL::Digest::SHA256.new
    digest_bytes = sha256.digest(body.presence || '')
    enc_digest   = Base64.strict_encode64(digest_bytes)
    digest       = "sha-256=#{enc_digest}"
    signing_data = [
      "(request-target): #{method.downcase} #{uri.presence || '/'}",
      "host: #{host}",
      "date: #{date_header}",
      "digest: #{digest}",
    ].join("\n")

    return false if
      digest != digest_header

    ok = false

    case signature_algorithm
    when 'ed25519'
      verify_key  = Ed25519::VerifyKey.new [account.ed25519_public_key].pack('H*')
      ok          = verify_key.verify(sig_bytes, signing_data) rescue false
    when 'rsa-pss-sha256'
      pub = OpenSSL::PKey::RSA.new(account.public_key)
      ok  = pub.verify_pss(sha256, sig_bytes, signing_data, salt_length: :auto, mgf1_hash: 'SHA256') rescue false
    when 'rsa-sha256'
      pub = OpenSSL::PKey::RSA.new(account.public_key)
      ok  = pub.verify(sha256, sig_bytes, signing_data) rescue false
    when 'ecdsa-p256'
      pub = OpenSSL::PKey::EC.new(account.ecdsa_public_key)
      ok  = pub.verify(sha256, sig_bytes, signing_data) rescue false
    end

    ok
  end

  def self.verify_legacy(account:, signature:, body:)
    sha256 = OpenSSL::Digest::SHA256.new
    pub    = OpenSSL::PKey::RSA.new(account.public_key)
    sig    = Base64.strict_decode64(signature)

    pub.verify(sha256, sig, body) rescue false
  end
end
