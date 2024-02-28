# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe MachineProcess, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching machine' do
        environment = create(:environment, account:)
        machine     = create(:machine, account:, environment:)
        process     = create(:process, account:, machine:)

        expect(process.environment).to eq machine.environment
      end

      it 'should not raise when environment matches machine' do
        environment = create(:environment, account:)
        machine     = create(:machine, account:, environment:)

        expect { create(:process, account:, environment:, machine:) }.to_not raise_error
      end

      it 'should raise when environment does not match machine' do
        environment = create(:environment, account:)
        machine     = create(:machine, account:, environment: nil)

        expect { create(:process, account:, environment:, machine:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches machine' do
        environment = create(:environment, account:)
        process     = create(:process, account:, environment:)

        expect { process.update!(machine: create(:machine, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match machine' do
        environment = create(:environment, account:)
        process     = create(:process, account:, environment:)

        expect { process.update!(machine: create(:machine, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
