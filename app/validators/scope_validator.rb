# frozen_string_literal: true

class ScopeValidator < ActiveModel::EachValidator
  def validate_each(record, association_name, association_record)
    return if
      association_record.nil?

    key = options.fetch(:by).to_s

    raise ArgumentError, ':by cannot be blank' if
      key.empty?

    # Assert that record scope matches association scope (i.e. self.account_id == assoc.account_id)
    record.errors.add(association_name, :blank, message: 'must exist') unless
      record.attributes[key] == association_record.attributes[key]
  end
end
