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

  describe '#components_attributes=' do
    it 'should not raise when component is valid' do
      machine = build(:machine, account:, components_attributes: [
        attributes_for(:component),
      ])

      expect { machine.save! }.to_not raise_error
    end

    it 'should raise when component is duplicated' do
      fingerprint = SecureRandom.hex
      machine     = build(:machine, account:, components_attributes: [
        attributes_for(:component, fingerprint:),
        attributes_for(:component, fingerprint:),
      ])

      expect { machine.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'should raise when component is invalid' do
      machine = build(:machine, account:, components_attributes: [
        attributes_for(:component, fingerprint: nil),
        attributes_for(:component),
      ])

      expect { machine.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#components=' do
    it 'should not raise when component is valid' do
      machine = build(:machine, account:, components: build_list(:component, 3))

      expect { machine.save! }.to_not raise_error
    end

    it 'should raise when component is duplicated' do
      machine = build(:machine, account:, components: build_list(:component, 3, fingerprint: SecureRandom.hex))

      expect { machine.save! }.to raise_error ActiveRecord::RecordNotUnique
    end

    it 'should raise when component is invalid' do
      machine = build(:machine, account:, components: build_list(:component, 3, fingerprint: nil))

      expect { machine.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end
end
