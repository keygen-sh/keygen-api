class UrlValidator < ActiveModel::EachValidator
  BLACKLISTED_HOSTS = %w[
    dist.keygen.sh
    app.keygen.sh
    api.keygen.sh
    keygen.sh
    localhost
  ].freeze

  def validate_each(record, attribute, value)
    uri = URI.parse value

    record.errors.add attribute, :protocol_invalid, message: "must be a valid URL using one of the following protocols: #{options[:protocols].join ", "}" unless valid_protocol? uri
    record.errors.add attribute, :host_invalid, message: "must be a URL with a valid host" unless valid_host? uri
  rescue URI::InvalidURIError,
         URI::InvalidComponentError,
         URI::BadURIError
    record.errors.add attribute, :invalid, message: "must be a valid URL"
  end

  private

  def default_options
    @default_options ||= { protocols: %w(http https) }
  end

  def valid_protocol?(uri)
    return false if uri.nil? || uri.scheme.nil?

    options = default_options.merge self.options
    protos = options[:protocols]
    scheme = uri.scheme

    protos.include? scheme
  end

  def valid_host?(uri)
    return false if uri.nil? || uri.host.nil?

    host = uri.host
    return false if BLACKLISTED_HOSTS.include? host

    host =~ /^.*?\.[a-zA-Z]{2,}$/
  end
end
