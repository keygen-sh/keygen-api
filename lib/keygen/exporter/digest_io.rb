# frozen_string_literal: true

require 'delegate'
require 'digest'

module Keygen
  module Exporter
    ##
    # Wraps an IO object and decorates it with a digest function.
    #
    # Example:
    #
    #   string_io = StringIO.new
    #   digest_io = Keygen::Exporter::DigestIO.new(string_io)
    #   digest_io.write('foo')
    #   digest_io.hexdigest => e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    #
    # This is a drop in replacement for IO.
    class DigestIO < SimpleDelegator
      delegate :digest, :hexdigest, :base64digest, :bubblebabble,
        to: :@digest

      def initialize(io, digest: Digest::SHA256.new)
        raise ArgumentError, 'digest object is required' if digest.nil?

        @digest = digest

        super(io)
      end

      def write(*data)
        data.each { @digest << _1 }

        super
      end
    end
  end
end
