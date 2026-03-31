# frozen_string_literal: true

module Orderable
  extend ActiveSupport::Concern

  included do
    scope :with_order, -> dir {
      case dir.to_s.upcase
      when 'DESC'
        ordered(:desc)
      when 'ASC'
        ordered(:asc)
      else
        raise Keygen::Error::InvalidParameterError.new(parameter: 'order'), 'order is invalid'
      end
    }
  end
end
