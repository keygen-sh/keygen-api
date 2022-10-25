# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen::EE::ProtectedRecord, type: :ee do
  subject do
    Class.new do
      include Keygen::EE::ProtectedRecord

      def self.ok? = nil
      def ok?      = nil
    end
  end

  it 'should not protect the singleton record' do
    expect { subject.ok? }.to_not raise_error
  end

  it 'should not protect an instance record' do
    expect { subject.new.ok? }.to_not raise_error
  end

  within_console do
    within_ce do
      it 'should protect the singleton record' do
        expect { subject.ok? }.to raise_error Keygen::EE::ProtectedMethodError
      end

      it 'should protect an instance record' do
        expect { subject.new.ok? }.to raise_error Keygen::EE::ProtectedMethodError
      end
    end

    within_ee do
      it 'should not protect the singleton record' do
        expect { subject.ok? }.to_not raise_error
      end

      it 'should not protect an instance record' do
        expect { subject.new.ok? }.to_not raise_error
      end
    end

    context 'with entitlements' do
      within_ce do
        it 'should block protected record' do
          klass = Class.new do
            include Keygen::EE::ProtectedRecord[entitlements: %i[test]]

            def self.ok? = nil
          end

          expect { klass.ok? }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end

      within_ee do
        it 'should allow protected record when entitled' do
          klass = Class.new do
            include Keygen::EE::ProtectedRecord[entitlements: %i[test]]

            def ok? = nil
          end

          expect { subject.new.ok? }.to_not raise_error
        end

        it 'should block protected record when not entitled' do
          klass = Class.new do
            include Keygen::EE::ProtectedRecord[entitlements: %i[other]]

            def self.ok? = nil
          end

          expect { subject.ok? }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end
    end
  end
end
