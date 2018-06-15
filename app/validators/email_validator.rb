class EmailValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    record.errors.add attribute, :invalid, message: "must be a valid email" unless valid_email?(value)
  end

  private

  def valid_email?(value)
    return false if value.nil?
    value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  end
end
