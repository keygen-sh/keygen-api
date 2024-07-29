# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'null_association'

describe NullAssociation do
  describe '.belongs_to' do
    temporary_table :tmp_accounts do |t|
      t.references :tmp_plan
      t.string :name
    end

    temporary_table :tmp_plans do |t|
      t.string :name
    end

    temporary_model :tmp_plan
    temporary_model :tmp_null_plan, table_name: nil, base_class: nil

    context 'with a class' do
      temporary_model :tmp_account do
        include NullAssociation::Macro

        belongs_to :tmp_plan, optional: true, null_object: TmpNullPlan
      end

      it 'should return a null object for a nil association' do
        instance = TmpAccount.new(tmp_plan: nil)

        expect(instance.tmp_plan).to be_a TmpNullPlan
      end

      it 'should not return a null object for a present association' do
        instance = TmpAccount.new(tmp_plan: TmpPlan.new)

        expect(instance.tmp_plan).to be_a TmpPlan
      end
    end

    context 'with a string' do
      temporary_model :tmp_account do
        include NullAssociation::Macro

        belongs_to :tmp_plan, optional: true, null_object: 'TmpNullPlan'
      end

      it 'should return a null object for a nil association' do
        instance = TmpAccount.new(tmp_plan: nil)

        expect(instance.tmp_plan).to be_a TmpNullPlan
      end

      it 'should not return a null object for a present association' do
        instance = TmpAccount.new(tmp_plan: TmpPlan.new)

        expect(instance.tmp_plan).to be_a TmpPlan
      end
    end

    # FIXME(ezekg) implement support for singletons?
    context 'with a singleton' do
      temporary_model :tmp_null_plan_singleton, table_name: nil, base_class: nil do
        include Singleton
      end

      temporary_model :tmp_account do
        include NullAssociation::Macro
      end

      it 'should raise' do
        expect { TmpAccount.belongs_to :tmp_plan, optional: true, null_object: TmpNullPlanSingleton.instance }
          .to raise_error ArgumentError
      end
    end

    # FIXME(ezekg) implement support for instances?
    context 'with an instance' do
      temporary_model :tmp_account do
        include NullAssociation::Macro
      end

      it 'should raise' do
        expect { TmpAccount.belongs_to :tmp_plan, optional: true, null_object: TmpNullPlan.new }
          .to raise_error ArgumentError
      end
    end

    context 'without :optional' do
      temporary_model :tmp_account do
        include NullAssociation::Macro
      end

      it 'should raise' do
        expect { TmpAccount.belongs_to :tmp_plan, optional: false, null_object: TmpNullPlan }
          .to raise_error ArgumentError
      end
    end

    context 'with :required' do
      temporary_model :tmp_account do
        include NullAssociation::Macro
      end

      it 'should raise' do
        expect { TmpAccount.belongs_to :tmp_plan, required: true, null_object: TmpNullPlan }
          .to raise_error ArgumentError
      end
    end
  end

  describe '.has_one' do
    temporary_table :tmp_accounts do |t|
      t.string :name
    end

    temporary_table :tmp_billings do |t|
      t.references :tmp_account
      t.string :name
    end

    temporary_model :tmp_billing
    temporary_model :tmp_null_billing, table_name: nil, base_class: nil

    context 'with a class' do
      temporary_model :tmp_account do
        include NullAssociation::Macro

        has_one :tmp_billing, null_object: TmpNullBilling
      end

      it 'should return a null object for a nil association' do
        instance = TmpAccount.new(tmp_billing: nil)

        expect(instance.tmp_billing).to be_a TmpNullBilling
      end

      it 'should not return a null object for a present association' do
        instance = TmpAccount.new(tmp_billing: TmpBilling.new)

        expect(instance.tmp_billing).to be_a TmpBilling
      end
    end

    context 'with a string' do
      temporary_model :tmp_account do
        include NullAssociation::Macro

        has_one :tmp_billing, null_object: 'TmpNullBilling'
      end

      it 'should return a null object for a nil association' do
        instance = TmpAccount.new(tmp_billing: nil)

        expect(instance.tmp_billing).to be_a TmpNullBilling
      end

      it 'should not return a null object for a present association' do
        instance = TmpAccount.new(tmp_billing: TmpBilling.new)

        expect(instance.tmp_billing).to be_a TmpBilling
      end
    end

    # FIXME(ezekg) implement support for singletons?
    context 'with a singleton' do
      temporary_model :tmp_null_billing_singleton, table_name: nil, base_class: nil do
        include Singleton
      end

      temporary_model :tmp_account do
        include NullAssociation::Macro
      end

      it 'should raise' do
        expect { TmpAccount.has_one :tmp_billing, null_object: TmpNullBillingSingleton.instance }
          .to raise_error ArgumentError
      end
    end

    # FIXME(ezekg) implement support for instances?
    context 'with an instance' do
      temporary_model :tmp_account do
        include NullAssociation::Macro
      end

      it 'should raise' do
        expect { TmpAccount.has_one :tmp_billing, null_object: TmpNullBilling.new }
          .to raise_error ArgumentError
      end
    end
  end
end
