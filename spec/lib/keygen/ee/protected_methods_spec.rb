# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'keygen'

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

  it 'should not raise when included' do
    expect { Class.new { include Keygen::EE::ProtectedMethods[:foo] } }.to_not raise_error
  end

  it 'should not raise when prepended' do
    expect { Class.new { prepend Keygen::EE::ProtectedMethods[:foo] } }.to_not raise_error
  end

  it 'should raise when included without []' do
    expect { Class.new { include Keygen::EE::ProtectedMethods } }
      .to raise_error NotImplementedError
  end

  it 'should raise when prepended without []' do
    expect { Class.new { include Keygen::EE::ProtectedMethods } }
      .to raise_error NotImplementedError
  end

  it 'should raise when positional and keyword args are mixed' do
    expect { Class.new { include Keygen::EE::ProtectedMethods[:foo, singleton_methods: %i[bar], instance_methods: %i[baz]] } }
      .to raise_error ArgumentError
  end

  it 'should not apply protections outside of a console environment' do
    expect { subject.foo }.to_not raise_error
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

    context 'when protecting singleton methods defined before inclusion' do
      subject do
        Class.new do
          def self.foo = nil
          def foo = nil

          include Keygen::EE::ProtectedMethods[singleton_methods: %i[foo]]
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

    context 'when protecting singleton methods defined after inclusion' do
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

    context 'when protecting instance methods defined before inclusion' do
      subject do
        Class.new do
          def self.foo = nil
          def foo = nil

          include Keygen::EE::ProtectedMethods[instance_methods: %i[foo]]
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

    context 'when protecting instance methods defined after inclusion' do
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

    context 'when included multiple times' do
      subject do
        Class.new do
          include Keygen::EE::ProtectedMethods[:foo, entitlements: %i[foo]]
          include Keygen::EE::ProtectedMethods[:bar, entitlements: %i[bar]]
          include Keygen::EE::ProtectedMethods[:baz]

          def foo = nil
          def bar = nil
          def baz = nil
        end
      end

      within_ce do
        it 'should block protected method' do
          expect { subject.new.foo }.to raise_error Keygen::EE::ProtectedMethodError
          expect { subject.new.bar }.to raise_error Keygen::EE::ProtectedMethodError
          expect { subject.new.baz }.to raise_error Keygen::EE::ProtectedMethodError
        end
      end

      within_ee entitlements: %i[foo bar] do
        it 'should allow protected method when entitled' do
          expect { subject.new.foo }.to_not raise_error
          expect { subject.new.bar }.to_not raise_error
          expect { subject.new.baz }.to_not raise_error
        end
      end

      within_ee entitlements: %i[foo] do
        it 'should allow protected method when entitled' do
          expect { subject.new.foo }.to_not raise_error
          expect { subject.new.bar }.to raise_error Keygen::EE::ProtectedMethodError
          expect { subject.new.baz }.to_not raise_error
        end
      end

      within_ee entitlements: %i[bar] do
        it 'should allow protected method when entitled' do
          expect { subject.new.foo }.to raise_error Keygen::EE::ProtectedMethodError
          expect { subject.new.bar }.to_not raise_error
          expect { subject.new.baz }.to_not raise_error
        end
      end

      within_ee entitlements: [] do
        it 'should block protected method when unentitled' do
          expect { subject.new.foo }.to raise_error Keygen::EE::ProtectedMethodError
          expect { subject.new.bar }.to raise_error Keygen::EE::ProtectedMethodError
          expect { subject.new.baz }.to_not raise_error
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

  context 'ancestors' do
    subject do
      Class.new do
        include Keygen::EE::ProtectedMethods[:v]

        def initialize(v) = @v = v
        def v = @v
      end
    end

    it 'should not define singleton protection module outside of a console environment' do
      expect(subject.const_defined?(:ProtectedSingletonMethods)).to be false
    end

    it 'should not define instance protection module outside of a console environment' do
      expect(subject.const_defined?(:ProtectedInstanceMethods)).to be false
    end

    within_console do
      it 'should define singleton protection module inside of a console environment' do
        expect(subject.const_defined?(:ProtectedSingletonMethods)).to be true
        expect(subject.singleton_class.ancestors).to include(
          subject.const_get(:ProtectedSingletonMethods),
        )
      end

      it 'should define instance protection module inside of a console environment' do
        expect(subject.const_defined?(:ProtectedInstanceMethods)).to be true
        expect(subject.ancestors).to include(
          subject.const_get(:ProtectedInstanceMethods),
        )
      end

      within_ee do
        it 'should respect singleton method ancestor chain' do
          calls = []

          base = Class.new
          base.define_singleton_method(:call) { calls << :foo; :foo }

          mod = Module.new do
            define_method(:call) { calls << :bar; super() }
          end

          klass = Class.new(base) do
            include Keygen::EE::ProtectedMethods[singleton_methods: %i[call]]

            extend mod
          end

          expect(klass.call).to eq :foo
          expect(calls).to eq %i[bar foo]
        end

        it 'should respect instance method ancestor chain' do
          calls = []

          base = Class.new
          base.define_method(:call) { calls << :foo; :foo }

          mod = Module.new do
            define_method(:call) { calls << :bar; super() }
          end

          klass = Class.new(base) do
            include Keygen::EE::ProtectedMethods[instance_methods: %i[call]]

            include mod
          end

          expect(klass.new.call).to eq :foo
          expect(calls).to eq %i[bar foo]
        end
      end
    end
  end
end
