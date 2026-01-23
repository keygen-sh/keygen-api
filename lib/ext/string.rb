# frozen_string_literal: true

class String
  def to_bool = ActiveModel::Type::Boolean.new.cast(self).present?
end
