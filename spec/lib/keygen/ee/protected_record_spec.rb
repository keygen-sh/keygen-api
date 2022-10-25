# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen::EE::ProtectedRecord, type: :ee do
  subject do
    Class.new do
      include Keygen::EE::ProtectedRecord

      Keygen::EE::ProtectedRecord::SINGLETON_METHODS.each do |method|
        define_singleton_method method do |*args, **kwargs|
          nil
        end
      end

      Keygen::EE::ProtectedRecord::INSTANCE_METHODS.each do |method|
        define_method method do |*args, **kwargs|
          nil
        end
      end
    end
  end

  Keygen::EE::ProtectedRecord::SINGLETON_METHODS.each do |method|
    it "should allow querying the record with .#{method}" do
      expect { subject.send(method) }.to_not raise_error
    end
  end

  Keygen::EE::ProtectedRecord::INSTANCE_METHODS.each do |method|
    it "should allow querying the record with ##{method}" do
      expect { subject.new.send(method) }.to_not raise_error
    end
  end

  within_console do
    within_ce do
      Keygen::EE::ProtectedRecord::SINGLETON_METHODS.each do |method|
        it "should block querying the record with .#{method}" do
          expect { subject.send(method) }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end

      Keygen::EE::ProtectedRecord::INSTANCE_METHODS.each do |method|
        it "should block querying the record with ##{method}" do
          expect { subject.new.send(method) }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end
    end

    within_ee do
      Keygen::EE::ProtectedRecord::SINGLETON_METHODS.each do |method|
        it "should allow querying the record with .#{method}" do
          expect { subject.send(method) }.to_not raise_error
        end
      end

      Keygen::EE::ProtectedRecord::INSTANCE_METHODS.each do |method|
        it "should allow querying the record with ##{method}" do
          expect { subject.new.send(method) }.to_not raise_error
        end
      end
    end

    context 'when record is protected with entitlements' do
      subject do
        Class.new do
          include Keygen::EE::ProtectedRecord[entitlements: %i[test]]

          def self.all = nil
          def reload   = nil
        end
      end

      within_ce do
        it 'should block querying protected record' do
          expect { subject.new.reload }.to raise_error Keygen::EE::ProtectedMethodError
          expect { subject.all }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end

      within_ee entitlements: %i[test] do
        it 'should allow querying protected record when entitled' do
          expect { subject.new.reload }.to_not raise_error
          expect { subject.all }.to_not raise_error
        end
      end

      within_ee entitlements: [] do
        it 'should block querying protected record when unentitled' do
          expect { subject.new.reload }.to raise_error Keygen::EE::ProtectedMethodError
          expect { subject.all }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end
    end
  end
end
