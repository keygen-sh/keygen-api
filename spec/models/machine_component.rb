# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe MachineComponent, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching machine' do
        environment = create(:environment, account:)
        machine     = create(:machine, account:, environment:)
        component   = create(:component, account:, machine:)

        expect(component.environment).to eq machine.environment
      end

      it 'should not raise when environment matches machine' do
        environment = create(:environment, account:)
        machine     = create(:machine, account:, environment:)

        expect { create(:component, account:, environment:, machine:) }.to_not raise_error
      end

      it 'should raise when environment does not match machine' do
        environment = create(:environment, account:)
        machine     = create(:machine, account:, environment: nil)

        expect { create(:component, account:, environment:, machine:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches machine' do
        environment = create(:environment, account:)
        component   = create(:component, account:, environment:)

        expect { component.update!(machine: create(:machine, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match machine' do
        environment = create(:environment, account:)
        component   = create(:component, account:, environment:)

        expect { component.update!(machine: create(:machine, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
