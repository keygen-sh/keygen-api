# frozen_string_literal: true

class ReleaseDownloadSpark < ClickhouseRecord
  include Accountable, Environmental

  has_environment
  has_account
end
