# frozen_string_literal: true

class LicenseValidationSpark < ClickhouseRecord
  include Accountable, Environmental

  has_environment
  has_account
end
