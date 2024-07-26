# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'null_association'

describe NullAssociation do
  subject do
    Class.new ActiveRecord::Base do
      def self.table_name = 'accounts'
      def self.name       = 'Account'

      include NullAssociation::Macro
    end
  end

  describe '.belongs_to' do
    let(:null_plan_class) { NullPlan }
    let(:plan_class)      { Plan }

    context 'with a class' do
      subject do
        null_object = null_plan_class

        super().tap do |klass|
          klass.belongs_to :plan, optional: true, null_object:
        end
      end

      it 'should return a null object for a nil association' do
        instance = subject.new(plan: nil)

        expect(instance.plan).to be_a null_plan_class
      end

      it 'should not return a null object for a present association' do
        instance = subject.new(plan: plan_class.new)

        expect(instance.plan).to be_a plan_class
      end
    end

    context 'with a string' do
      subject do
        null_object = null_plan_class.name

        super().tap do |klass|
          klass.belongs_to :plan, optional: true, null_object:
        end
      end

      it 'should return a null object for a nil association' do
        instance = subject.new(plan: nil)

        expect(instance.plan).to be_a null_plan_class
      end

      it 'should not return a null object for a present association' do
        instance = subject.new(plan: plan_class.new)

        expect(instance.plan).to be_a plan_class
      end
    end

    # FIXME(ezekg) implement support for singletons?
    context 'with a singleton' do
      subject do
        null_object = Class.new(null_plan_class) { include Singleton }
                           .instance

        super().tap do |klass|
          klass.belongs_to :plan, optional: true, null_object:
        end
      end

      it 'should raise' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    # FIXME(ezekg) implement support for instances?
    context 'with an instance' do
      subject do
        null_object = null_plan_class.new

        super().tap do |klass|
          klass.belongs_to :plan, optional: true, null_object:
        end
      end

      it 'should raise' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'without :optional' do
      subject do
        null_object = null_plan_class

        super().tap do |klass|
          klass.belongs_to :plan, optional: false, null_object:
        end
      end

      it 'should raise' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'with :required' do
      subject do
        null_object = null_plan_class

        super().tap do |klass|
          klass.belongs_to :plan, required: true, null_object:
        end
      end

      it 'should raise' do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end

  describe '.has_one' do
    let(:null_billing_class) { NullPlan } # FIXME(ezekg) NullBilling doesn't exist
    let(:billing_class)      { Billing }

    context 'with a class' do
      subject do
        null_object = null_billing_class

        super().tap do |klass|
          klass.has_one :billing, null_object:
        end
      end

      it 'should return a null object for a nil association' do
        instance = subject.new(billing: nil)

        expect(instance.billing).to be_a null_billing_class
      end

      it 'should not return a null object for a present association' do
        instance = subject.new(billing: billing_class.new)

        expect(instance.billing).to be_a billing_class
      end
    end

    context 'with a string' do
      subject do
        null_object = null_billing_class.name

        super().tap do |klass|
          klass.has_one :billing, null_object:
        end
      end

      it 'should return a null object for a nil association' do
        instance = subject.new(billing: nil)

        expect(instance.billing).to be_a null_billing_class
      end

      it 'should not return a null object for a present association' do
        instance = subject.new(billing: billing_class.new)

        expect(instance.billing).to be_a billing_class
      end
    end

    # FIXME(ezekg) implement support for singletons?
    context 'with a singleton' do
      subject do
        null_object = Class.new(null_billing_class) { include Singleton }
                           .instance

        super().tap do |klass|
          klass.has_one :billing, null_object:
        end
      end

      it 'should raise' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    # FIXME(ezekg) implement support for instances?
    context 'with an instance' do
      subject do
        null_object = null_billing_class.new

        super().tap do |klass|
          klass.has_one :billing, null_object:
        end
      end

      it 'should raise' do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end
end
