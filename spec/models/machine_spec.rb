# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Machine, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching license' do
        environment = create(:environment, account:)
        license     = create(:license, account:, environment:)
        machine     = create(:machine, account:, license:)

        expect(machine.environment).to eq license.environment
      end

      it 'should not raise when environment matches license' do
        environment = create(:environment, account:)
        license     = create(:license, account:, environment:)

        expect { create(:machine, account:, environment:, license:) }.to_not raise_error
      end

      it 'should raise when environment does not match license' do
        environment = create(:environment, account:)
        license     = create(:license, account:, environment: nil)

        expect { create(:machine, account:, environment:, license:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches license' do
        environment = create(:environment, account:)
        machine     = create(:machine, account:, environment:)

        expect { machine.update!(license: create(:license, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match license' do
        environment = create(:environment, account:)
        machine     = create(:machine, account:, environment:)

        expect { machine.update!(license: create(:license, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
