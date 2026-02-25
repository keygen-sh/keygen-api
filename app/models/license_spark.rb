# frozen_string_literal: true

class LicenseSpark < ClickhouseRecord
  include Accountable, Environmental

  has_environment
  has_account
end
