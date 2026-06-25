# frozen_string_literal: true

class ActiveLicensedUserSpark < ClickhouseRecord
  include Accountable, Environmental

  has_environment
  has_account
end
