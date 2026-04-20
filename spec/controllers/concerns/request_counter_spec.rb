# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RequestCounter, type: :concern do
  controller_class = Class.new(ActionController::API) do
    include RequestCounter

    def internal_request? = false
  end

  let(:controller) { controller_class.new }
  let(:request)    { instance_double(ActionDispatch::Request) }
  let(:response)   { instance_double(ActionDispatch::Response) }

  before do
    allow(controller).to receive(:request).and_return(request)
    allow(controller).to receive(:response).and_return(response)
  end

  describe '#count_request?' do
    let(:account) { build(:account) }

    after { Current.reset }

    it 'returns false for an external request with no account' do
      Current.account = nil

      expect(controller.send(:count_request?)).to be false
    end

    it 'returns false for an internal request with no account' do
      allow(controller).to receive(:internal_request?).and_return(true)

      Current.account = nil

      expect(controller.send(:count_request?)).to be false
    end

    it 'returns true for an external request with an account' do
      Current.account = account

      expect(controller.send(:count_request?)).to be true
    end

    it 'returns false for an internal request with an account' do
      allow(controller).to receive(:internal_request?).and_return(true)

      Current.account = account

      expect(controller.send(:count_request?)).to be false
    end
  end
end
