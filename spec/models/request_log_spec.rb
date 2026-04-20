# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RequestLog, type: :model do
  let(:account) { create(:account, plan: build(:plan, :ent, request_log_retention_duration: rand(1.day..365.days))) }

  before { Current.account = account }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '.external' do
    it 'excludes internal origins' do
      api = create(:request_log, :external, account:)
      ui  = create(:request_log, :internal, account:)

      expect(RequestLog.external).to     include(api)
      expect(RequestLog.external).not_to include(ui)
    end
  end

  describe '.internal' do
    it 'excludes external origins' do
      api = create(:request_log, :external, account:)
      ui  = create(:request_log, :internal, account:)

      expect(RequestLog.internal).not_to include(api)
      expect(RequestLog.internal).to     include(ui)
    end
  end
end
