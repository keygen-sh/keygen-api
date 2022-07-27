# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ProductPolicy, type: :policy do
  subject { described_class.new(context, product) }

  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  context 'for anonymous' do
    let(:context) { authorization_context(account:) }

    it 'denies index access' do
      expect { subject.index? }.to raise_error Pundit::NotAuthorizedError
    end

    it 'denies show access' do
      expect { subject.show? }.to raise_error Pundit::NotAuthorizedError
    end

    it 'denies create access' do
      expect { subject.create? }.to raise_error Pundit::NotAuthorizedError
    end
  end
end
