# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    record.errors.add attribute, :invalid, message: "must be a valid email" unless EmailValidator.valid?(value)
  end

  def self.valid?(value)
    return false if value.nil?

    value in EMAIL_RE
  end
end
