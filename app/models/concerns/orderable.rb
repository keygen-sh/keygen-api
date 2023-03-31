# frozen_string_literal: true

module Orderable
  extend ActiveSupport::Concern

  included do
    scope :with_order, -> order {
      case order.to_s.upcase
      when 'DESC'
        reorder(created_at: :desc)
      when 'ASC'
        reorder(created_at: :asc)
      else
        raise Keygen::Error::InvalidParameterError.new(parameter: 'order'), 'order is invalid'
      end
    }
  end
end
