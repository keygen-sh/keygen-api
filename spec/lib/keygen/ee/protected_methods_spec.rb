# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen::EE::ProtectedMethods, type: :ee do
  subject do
    Class.new do
      include Keygen::EE::ProtectedMethods[:foo, :baz]

      def self.foo = nil
      def self.bar = nil
      def baz      = nil
      def qux      = nil
    end
  end

  it 'should raise when positional and keyword args are mixed' do
    expect { Class.new { include Keygen::EE::ProtectedMethods[:foo, singleton_methods: %i[bar], instance_methods: %i[baz]] } }
      .to raise_error ArgumentError
  end

  it 'should not include the module outside of a console environment' do
    expect(subject.ancestors).to_not include Keygen::EE::ProtectedMethods::MethodBouncer
  end

  it 'should not block a predefined set of singleton methods' do
    expect { subject.foo }.to_not raise_error
  end

  it 'should not block other singleton methods' do
    expect { subject.bar }.to_not raise_error
  end

  it 'should not block a predefined set of instance methods' do
    expect { subject.new.baz }.to_not raise_error
  end

  it 'should not block other instance methods' do
    expect { subject.new.qux }.to_not raise_error
  end

  within_console do
    it 'should include the module within a console environment' do
      expect(subject.ancestors).to include Keygen::EE::ProtectedMethods::MethodBouncer
    end

    within_ce do
      it 'should block a predefined set of singleton methods' do
        expect { subject.foo }.to raise_error Keygen::EE::ProtectedMethodError
      end

      it 'should allow other singleton methods' do
        expect { subject.bar }.to_not raise_error
      end

      it 'should block a predefined set of instance methods' do
        expect { subject.new.baz }.to raise_error Keygen::EE::ProtectedMethodError
      end

      it 'should allow other instance methods' do
        expect { subject.new.qux }.to_not raise_error
      end
    end

    within_ee do
      it 'should allow a predefined set of singleton methods' do
        expect { subject.foo }.to_not raise_error
      end

      it 'should allow other singleton methods' do
        expect { subject.bar }.to_not raise_error
      end

      it 'should allow a predefined set of instance methods' do
        expect { subject.new.baz }.to_not raise_error
      end

      it 'should allow other instance methods' do
        expect { subject.new.qux }.to_not raise_error
      end
    end

    context 'when protecting singleton methods' do
      subject do
        Class.new do
          include Keygen::EE::ProtectedMethods[singleton_methods: %i[foo]]

          def self.foo = nil
          def foo = nil
        end
      end

      within_ce do
        it 'should block the singleton method' do
          expect { subject.foo }.to raise_error Keygen::EE::ProtectedMethodError
        end

        it 'should allow the instance method' do
          expect { subject.new.foo }.to_not raise_error
        end
      end

      within_ee do
        it 'should allow the singleton method' do
          expect { subject.foo }.to_not raise_error
        end

        it 'should allow the instance method' do
          expect { subject.new.foo }.to_not raise_error
        end
      end
    end

    context 'when protecting instance methods' do
      subject do
        Class.new do
          include Keygen::EE::ProtectedMethods[instance_methods: %i[foo]]

          def self.foo = nil
          def foo = nil
        end
      end

      within_ce do
        it 'should allow the singleton method' do
          expect { subject.foo }.to_not raise_error
        end

        it 'should block the instance method' do
          expect { subject.new.foo }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end

      within_ee do
        it 'should allow the singleton method' do
          expect { subject.foo }.to_not raise_error
        end

        it 'should allow the instance method' do
          expect { subject.new.foo }.to_not raise_error
        end
      end
    end

    context 'when using inheritance' do
      subject do
        parent = Class.new do
          def self.foo = nil
        end

        Class.new(parent) do
          include Keygen::EE::ProtectedMethods[:foo, :baz]
        end
      end

      within_ce do
        it 'should block inherited method' do
          expect { subject.foo }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end

      within_ee do
        it 'should allow inherited method' do
          expect { subject.foo }.to_not raise_error
        end
      end
    end

    context 'when methods are protected with entitlements' do
      subject do
        Class.new do
          include Keygen::EE::ProtectedMethods[:foo, entitlements: %i[test]]

          def foo = nil
        end
      end

      within_ce do
        it 'should block protected method' do
          expect { subject.new.foo }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end

      within_ee entitlements: %i[test] do
        it 'should allow protected method when entitled' do
          expect { subject.new.foo }.to_not raise_error
        end
      end

      within_ee entitlements: [] do
        it 'should block protected method when unentitled' do
          expect { subject.new.foo }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end
    end
  end

  context 'bindings' do
    subject do
      Class.new do
        include Keygen::EE::ProtectedMethods[:v]

        def initialize(v) = @v = v
        def v = @v
      end
    end

    let(:t1) { subject.new(1) }
    let(:t2) { subject.new(2) }

    it 'should not fubar method bindings' do
      expect(t1.v).to eq 1
      expect(t2.v).to eq 2
    end

    within_console do
      within_ce do
        it 'should bind instance methods to the correct object' do
          expect { t1.v }.to raise_error Keygen::EE::ProtectedMethodError
          expect { t2.v }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end

      within_ee do
        it 'should bind instance methods to the correct object' do
          expect(t1.v).to eq 1
          expect(t2.v).to eq 2
        end
      end
    end
  end
end
