module Billable
  extend ActiveSupport::Concern

  included do
    Billing::AVAILABLE_EVENTS.each do |event|
      delegate "#{event}", to: :billing, allow_nil: true
    end

    Billing::AVAILABLE_STATES.each do |state|
      delegate "#{state}?", to: :billing, allow_nil: true
      delegate "#{state}", to: :billing, allow_nil: true
    end

    delegate "active?", to: :billing, allow_nil: true
  end
end
