class UrlValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    record.errors.add attribute, "must be a valid URL using one of the following protocols: #{options[:protocols].join ", "}" unless valid_url?(value)
  end

  private

  def default_options
    @default_options ||= { protocols: %w(http https) }
  end

  def valid_url?(value)
    return false if value.nil?

    options = default_options.merge(self.options)

    value.strip!
    value =~ /\A#{URI.regexp(options[:protocols])}\z/
  end
end
