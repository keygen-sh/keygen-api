# frozen_string_literal: true

class MachineSpark < ClickhouseRecord
  include Accountable, Environmental

  has_environment
  has_account
end
