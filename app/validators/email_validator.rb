# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    record.errors.add attribute, :invalid, message: "must be a valid email" unless EmailValidator.valid_email?(value)
  end

  def self.valid?(value)
    return false if value.nil?

    m = value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

    !m.nil?
  end
end
