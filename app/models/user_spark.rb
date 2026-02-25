# frozen_string_literal: true

class UserSpark < ClickhouseRecord
  include Accountable, Environmental

  has_environment
  has_account
end
