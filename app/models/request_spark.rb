# frozen_string_literal: true

class RequestSpark < ClickhouseRecord
  include Accountable, Environmental

  has_environment
  has_account
end
