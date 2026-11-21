# frozen_string_literal: true

class UrlValidator < ActiveModel::EachValidator
  BLACKLISTED_HOSTS = %w[
    dist.keygen.sh app.keygen.sh api.keygen.sh dashboard.keygen.sh portal.keygen.sh
    status.keygen.sh stats.keygen.sh keygen.sh localhost
  ].freeze

  def validate_each(record, attribute, value)
    uri = URI.parse(value)

    record.errors.add attribute, :protocol_invalid, message: "must be a valid URL using one of the following protocols: #{protocols.join(", ")}" unless valid_protocol?(uri)
    record.errors.add attribute, :host_invalid, message: 'must be a URL with a valid host' unless valid_host?(uri)
    record.errors.add attribute, :address_invalid, message: 'must resolve to a valid address' if resolve? && !valid_address?(uri)
  rescue URI::InvalidURIError,
         URI::InvalidComponentError,
         URI::BadURIError
    record.errors.add attribute, :invalid, message: 'must be a valid URL'
  end

  private

  def default_options
    @default_options ||= { protocols: %w(http https), resolve: true }
  end

  def protocols = default_options.merge(options)[:protocols]
  def resolve?  = default_options.merge(options)[:resolve]

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
    return false if
      uri.nil? || uri.host.nil?

    HostResolver.new(uri.host).ipaddrs.any?
  end
end
