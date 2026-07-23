# frozen_string_literal: true

require 'resolv'

class UrlValidator < ActiveModel::EachValidator
  BLACKLISTED_HOSTS = %w[
    dist.keygen.sh app.keygen.sh api.keygen.sh dashboard.keygen.sh portal.keygen.sh
    status.keygen.sh stats.keygen.sh keygen.sh localhost
  ].freeze

  BLACKLISTED_IPV4 = %w[
    0.0.0.0/8 100.64.0.0/10 192.0.0.0/24 192.0.2.0/24 192.88.99.0/24
    198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4
    169.254.0.0/16 192.168.0.0/16 172.16.0.0/12 127.0.0.0/8
    240.0.0.0/4 10.0.0.0/8
  ].map { IPAddr.new(it) }
   .freeze

  BLACKLISTED_IPV6 = %w[
    ::/128 100::/64 2001::/32 2001:2::/48 2001:db8::/32 2002::/16
    fec0::/10 ff00::/8 fc00::/7 fe80::/10 ::1/128
  ].map { IPAddr.new(it) }
   .freeze

  NAT64_PREFIXES = %w[
    64:ff9b::/96 64:ff9b:1::/48
  ].map { IPAddr.new(it) }
   .freeze

  def validate_each(record, attribute, value)
    uri = URI.parse(value)

    record.errors.add attribute, :protocol_invalid, message: "must be a valid URL using one of the following protocols: #{protocols.join(", ")}" unless valid_protocol?(uri)
    record.errors.add attribute, :host_invalid, message: 'must be a URL with a valid host' unless valid_host?(uri)
    record.errors.add attribute, :address_invalid, message: 'must resolve to a valid address' unless valid_address?(uri)
  rescue URI::InvalidURIError,
         URI::InvalidComponentError,
         URI::BadURIError
    record.errors.add attribute, :invalid, message: 'must be a valid URL'
  end

  private

  def default_options
    @default_options ||= { protocols: %w(http https) }
  end

  def protocols = default_options.merge(options)[:protocols]

  def valid_protocol?(uri)
    return false if
      uri.nil? || uri.scheme.nil?

    protocols.include?(uri.scheme)
  end

  def valid_host?(uri)
    return false if
      uri.nil? || uri.host.nil?

    host = uri.host
    return false if
      blacklisted_host?(host)

    host =~ /\A.*?\.[a-zA-Z]{2,}\z/
  end

  def blacklisted_host?(host)
    host = host.downcase.delete_suffix('.')

    BLACKLISTED_HOSTS.any? do |blacklisted|
      host == blacklisted || host.end_with?(".#{blacklisted}")
    end
  end

  def valid_address?(uri)
    # NB(ezekg) self-hosted deployments may legitimately point webhooks at private or
    #           internal addresses, so allow explicit opt-in.
    return true if
      ENV.true?('KEYGEN_ALLOW_PRIVATE_ADDRESSES')

    public_address?(uri.host)
  end

  def public_address?(host)
    addrs = Resolv.getaddresses(host)
    return false if
      addrs.empty?

    addrs.all? do |addr|
      ip = IPAddr.new(addr)
      next false if
        ip.loopback? || ip.private? || ip.link_local? ||
        ip.ipv4_mapped? || ip.ipv4_compat?

      case
      when ip.ipv4?
        !blacklisted_ipv4?(ip)
      when embedded_ipv4?(ip)
        !blacklisted_ipv4?(embedded_ipv4(ip))
      else
        !blacklisted_ipv6?(ip)
      end
    end
  rescue IPAddr::InvalidAddressError,
         Resolv::ResolvError
    false
  end

  def blacklisted_ipv4?(ip) = BLACKLISTED_IPV4.any? { it.include?(ip) }
  def blacklisted_ipv6?(ip) = BLACKLISTED_IPV6.any? { it.include?(ip) }
  def embedded_ipv4?(ip)    = NAT64_PREFIXES.any? { it.include?(ip) }

  def embedded_ipv4(ip)
    IPAddr.new([ip.to_i & 0xffffffff].pack("N").unpack("C4").join("."))
  end
end
