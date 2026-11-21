# frozen_string_literal: true

require 'resolv'

class Hostname
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

  DNS_ATTEMPT_TIMEOUTS = [1, 2].freeze # seconds
  DNS_TIMEOUT          = 3.seconds
  DNS_RESOLVER         = Resolv.new([
    Resolv::Hosts.new,
    Resolv::DNS.new.tap { it.timeouts = DNS_ATTEMPT_TIMEOUTS },
  ])

  attr_reader :name

  def initialize(name)
    @name = name
  end

  # ipaddrs resolves the hostname to its IP addresses. it's empty when the hostname
  # doesn't resolve or when it resolves to any unacceptable address.
  #
  # NB(ezekg) requests must connect to one of these rather than to the hostname, since
  #           resolving the hostname again could return an address we never validated,
  #           e.g. an internal one, i.e. DNS rebinding.
  def ipaddrs
    addrs = Timeout.timeout(DNS_TIMEOUT) { DNS_RESOLVER.getaddresses(name) }

    addrs.all? { acceptable?(IPAddr.new(it)) } ? addrs : []
  rescue IPAddr::InvalidAddressError,
         Resolv::ResolvError,
         Timeout::Error
    []
  end

  private

  def acceptable?(ip)
    # NB(ezekg) self-hosted deployments may legitimately point webhooks at private or
    #           internal addresses, so allow explicitly permitted ranges.
    return true if
      allowed_private_address?(ip)

    return false if
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

  def allowed_private_address?(ip) = allowed_private_ranges.any? { it.include?(ip) }
  def allowed_private_ranges
    return [] unless
      ENV.key?('KEYGEN_ALLOWED_PRIVATE_ADDRESSES')

    # NB(ezekg) a comma-separated CIDR allowlist of otherwise-private ranges to permit,
    #           e.g. an internal service subnet for webhooks.
    ENV.fetch('KEYGEN_ALLOWED_PRIVATE_ADDRESSES') { '' }
       .split(',')
       .filter_map { IPAddr.new(it.strip) unless it.strip.empty? }
  end

  def blacklisted_ipv4?(ip) = BLACKLISTED_IPV4.any? { it.include?(ip) }
  def blacklisted_ipv6?(ip) = BLACKLISTED_IPV6.any? { it.include?(ip) }
  def embedded_ipv4?(ip)    = NAT64_PREFIXES.any? { it.include?(ip) }

  def embedded_ipv4(ip)
    IPAddr.new([ip.to_i & 0xffffffff].pack("N").unpack("C4").join("."))
  end
end
