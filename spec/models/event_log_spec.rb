# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe EventLog, type: :model do
  let(:account) { create(:account, plan: build(:plan, :ent, event_log_retention_duration: rand(1.day..365.days))) }

  before { Current.account = account }

  it_behaves_like :environmental
  it_behaves_like :accountable
end
