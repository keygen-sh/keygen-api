class UrlValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    unless valid_url?(value)
      record.errors.add(attribute, "must be a valid URL")
    end
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
