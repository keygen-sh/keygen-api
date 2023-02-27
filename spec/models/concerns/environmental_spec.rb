# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Environmental, type: :concern do
  let(:account) { create(:account) }

  describe '.has_environent' do
    let(:environmental) {
      Class.new ActiveRecord::Base do
        def self.table_name = 'licenses'
        def self.name       = 'License'

        include Environmental
      end
    }

    it 'should not raise' do
      expect { environmental.has_environment }.to_not raise_error
    end

    it 'should define an environment association' do
      environmental.has_environment

      association = environmental.reflect_on_association(:environment)

      expect(association).to_not be_nil
    end

    context 'without default' do
      before { environmental.has_environment }

      it 'should have a nil default' do
        instance = environmental.new

        expect(instance.environment_id).to be_nil
        expect(instance.environment).to be_nil
      end
    end

    context 'with default' do
      let(:environment) { create(:environment, account:) }

      context 'with string' do
        before {
          env = environment # close over environment

          environmental.has_environment default: -> { env.id }
        }

        it 'should have an environment default' do
          instance = environmental.new

          expect(instance.environment_id).to eq environment.id
          expect(instance.environment).to eq environment
        end
      end

      context 'with class' do
        before {
          env = environment # close over environment

          environmental.has_environment default: -> { env }
        }

        it 'should have an environment default' do
          instance = environmental.new

          expect(instance.environment_id).to eq environment.id
          expect(instance.environment).to eq environment
        end
      end

      context 'with other' do
        before {
          environmental.has_environment default: -> { Class.new }
        }

        it 'should have an environment default' do
          expect { environmental.new }.to raise_error NoMatchingPatternError
        end
      end
    end
  end

  # NOTE(ezekg) See :environmental shared examples for more tests
end
