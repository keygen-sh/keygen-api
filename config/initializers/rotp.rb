# FIXME(ezekg) Monkey patch ROTP to support `image` param.
#              See: https://github.com/mdp/rotp/pull/90
module ROTP
  class TOTP
    attr_reader :image

    def initialize(s, options = {})
      @interval = options[:interval] || DEFAULT_INTERVAL
      @issuer = options[:issuer]
      @image = options[:image]
      super
    end
  end

  class OTP
    class URI
      def parameters
        {
          secret: @otp.secret,
          image: @otp.image,
          issuer: issuer,
          algorithm: algorithm,
          digits: digits,
          period: period,
          counter: counter,
        }
          .reject { |_, v| v.nil? }
          .map { |k, v| "#{k}=#{ERB::Util.url_encode(v)}" }
          .join('&')
      end
    end
  end
end
