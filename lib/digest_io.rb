# frozen_string_literal: true

require 'digest'

class DigestIO < SimpleDelegator
  delegate :digest, :hexdigest, :base64digest, :bubblebabble,
    to: :@digest

  def initialize(io, digest: Digest::SHA256.new)
    raise ArgumentError, 'digest object is required' if digest.nil?

    @digest  = digest

    super(io)
  end

  # FIXME(ezekg) mark as written and don't rehash on read/rewind
  def write(*data)
    data.each { @digest << _1 }

    super
  end

  # TODO(ezekg) reset on rewind unless written
  # TODO(ezekg) hash on read
end
