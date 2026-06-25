# frozen_string_literal: true

class EventSpark < ClickhouseRecord
  include Accountable, Environmental

  has_environment
  has_account
end
