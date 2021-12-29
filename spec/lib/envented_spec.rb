# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join "lib", "envented"

describe Envented do
  before { Rails.cache.clear }
  after { Rails.cache.clear }

  let(:eventable) do
    klass = Class.new do
      include Envented::Callbacks

      attr_accessor :id
      attr_accessor :semaphore
      attr_accessor :calls

      def initialize(id:)
        @id        = id
        @semaphore = Mutex.new
        @calls     = 0
      end

      on_exclusive_event 'test.exclusive-event', :callback

      on_exclusive_event 'test.exclusive-event.wait-and-raise', :callback,
        raise_on_lock_error: true,
        wait_on_lock: true

      on_exclusive_event 'test.exclusive-event.raise', -> { sleep 1.second },
        raise_on_lock_error: true

      on_exclusive_event 'test.exclusive-event.timeout', -> { sleep 2.seconds },
        raise_on_lock_error: true,
        lock_wait_timeout: 1.second,
        wait_on_lock: true

      on_exclusive_event 'test.exclusive-event.wait', :callback,
        wait_on_lock: true

      on_exclusive_event 'test.exclusive-event.once', :callback_once,
        unless: :has_been_called?

      on_event 'test.event',    :callback
      on_event 'test.suffix.*', :callback
      on_event '*.test.prefix', :callback

      # Testing guard proc types and arities
      on_event 'test.if-proc.true',             :callback, if: -> { true }
      on_event 'test.if-proc.false',            :callback, if: -> { false }
      on_event 'test.if-proc-args.true',        :callback, if: -> _ { true }
      on_event 'test.if-proc-args.false',       :callback, if: -> _ { false }
      on_event 'test.if-symbol.true',           :callback, if: :true?
      on_event 'test.if-symbol.false',          :callback, if: :false?
      on_event 'test.if-symbol-args.true',      :callback, if: :true_with_args?
      on_event 'test.if-symbol-args.false',     :callback, if: :false_with_args?
      on_event 'test.unless-proc.true',         :callback, unless: -> { true }
      on_event 'test.unless-proc.false',        :callback, unless: -> { false }
      on_event 'test.unless-proc-args.true',    :callback, unless: -> _ { true }
      on_event 'test.unless-proc-args.false',   :callback, unless: -> _ { false }
      on_event 'test.unless-symbol.true',       :callback, unless: :true?
      on_event 'test.unless-symbol.false',      :callback, unless: :false?
      on_event 'test.unless-symbol-args.true',  :callback, unless: :true_with_args?
      on_event 'test.unless-symbol-args.false', :callback, unless: :false_with_args?

      # Testing callback proc types and arities
      on_event 'test.callback.proc',        -> { callback }
      on_event 'test.callback.proc-args',   -> x { callback_with_args(x) }
      on_event 'test.callback.symbol',      :callback
      on_event 'test.callback.symbol-args', :callback_with_args

      private

      def has_been_called?
        semaphore.synchronize { @calls > 0 }
      end

      def callback_once
        return if
          has_been_called?

        callback
      end

      def callback
        semaphore.synchronize { @calls += 1 }

        # Do work...
        sleep 0.1
      end

      def callback_with_args(_)
        callback
      end

      def true?
        true
      end

      def false?
        false
      end

      def true_with_args?(_)
        true?
      end

      def false_with_args?(_)
        false?
      end
    end

    klass.new(id: SecureRandom.uuid)
  end

  it 'should invoke callbacks on a valid event' do
    expect(eventable).to receive(:callback).once

    eventable.notify_of_event!('test.event')
  end

  it 'should not invoke callbacks on an invalid event' do
    expect(eventable).to_not receive(:callback)

    eventable.notify_of_event!('foo.bar')
  end

  it 'should invoke a proc callback with an arity of 0' do
    expect(eventable).to receive(:callback)

    eventable.notify_of_event!('test.callback.proc')
  end

  it 'should invoke a proc callback with an arity of 1' do
    expect(eventable).to receive(:callback_with_args)

    eventable.notify_of_event!('test.callback.proc-args')
  end

  it 'should invoke a symbol callback with an arity of 0' do
    expect(eventable).to receive(:callback)

    eventable.notify_of_event!('test.callback.symbol')
  end

  it 'should invoke a symbol callback with an arity of 1' do
    expect(eventable).to receive(:callback_with_args)

    eventable.notify_of_event!('test.callback.symbol-args')
  end

  it 'should invoke callbacks on a wildcard suffix event' do
    expect(eventable).to receive(:callback).once

    eventable.notify_of_event!('test.suffix.foo')
  end

  it 'should invoke callbacks on a wildcard prefix event' do
    expect(eventable).to receive(:callback).once

    eventable.notify_of_event!('foo.test.prefix')
  end

  it 'should not invoke callback twice on duplicate idempotency key' do
    expect(eventable).to receive(:callback).once

    key = SecureRandom.hex

    eventable.notify_of_event!('test.event', idempotency_key: key)
    eventable.notify_of_event!('test.event', idempotency_key: key)
  end

  it 'should invoke callbacks when idempotency keys are different' do
    expect(eventable).to receive(:callback).twice

    eventable.notify_of_event!('test.event', idempotency_key: SecureRandom.hex)
    eventable.notify_of_event!('test.event', idempotency_key: SecureRandom.hex)
  end

  context 'when using an :if guard clause' do
    it 'should invoke callbacks when :if is a proc/0 that returns true' do
      expect(eventable).to receive(:callback)

      eventable.notify_of_event!('test.if-proc.true')
    end

    it 'should not invoke callbacks when :if is a proc/0 that returns false' do
      expect(eventable).to_not receive(:callback)

      eventable.notify_of_event!('test.if-proc.false')
    end

    it 'should invoke callbacks when :if is a proc/1 that returns true' do
      expect(eventable).to receive(:callback)

      eventable.notify_of_event!('test.if-proc-args.true')
    end

    it 'should not invoke callbacks when :if is a proc/1 that returns false' do
      expect(eventable).to_not receive(:callback)

      eventable.notify_of_event!('test.if-proc-args.false')
    end

    it 'should invoke callbacks when :if is a method/0 symbol that returns true' do
      expect(eventable).to receive(:callback)

      eventable.notify_of_event!('test.if-symbol.true')
    end

    it 'should not invoke callbacks when :if is a method/0 symbol that returns false' do
      expect(eventable).to_not receive(:callback)

      eventable.notify_of_event!('test.if-symbol.false')
    end

    it 'should invoke callbacks when :if is a method/1 symbol that returns true' do
      expect(eventable).to receive(:callback)

      eventable.notify_of_event!('test.if-symbol-args.true')
    end

    it 'should not invoke callbacks when :if is a method/1 symbol that returns false' do
      expect(eventable).to_not receive(:callback)

      eventable.notify_of_event!('test.if-symbol-args.false')
    end
  end

  context 'when using an :unless guard clause' do
    it 'should not invoke callbacks when :unless is a proc/0 that returns true' do
      expect(eventable).to_not receive(:callback)

      eventable.notify_of_event!('test.unless-proc.true')
    end

    it 'should invoke callbacks when :unless is a proc/0 that returns false' do
      expect(eventable).to receive(:callback)

      eventable.notify_of_event!('test.unless-proc.false')
    end

    it 'should not invoke callbacks when :unless is a proc/1 that returns true' do
      expect(eventable).to_not receive(:callback)

      eventable.notify_of_event!('test.unless-proc-args.true')
    end

    it 'should invoke callbacks when :unless is a proc/1 that returns false' do
      expect(eventable).to receive(:callback)

      eventable.notify_of_event!('test.unless-proc-args.false')
    end

    it 'should not invoke callbacks when :unless is a method/0 symbol that returns true' do
      expect(eventable).to_not receive(:callback)

      eventable.notify_of_event!('test.unless-symbol.true')
    end

    it 'should invoke callbacks when :unless is a method/0 symbol that returns false' do
      expect(eventable).to receive(:callback)

      eventable.notify_of_event!('test.unless-symbol.false')
    end

    it 'should not invoke callbacks when :unless is a method/1 symbol that returns true' do
      expect(eventable).to_not receive(:callback)

      eventable.notify_of_event!('test.unless-symbol-args.true')
    end

    it 'should invoke callbacks when :unless is a method/1 symbol that returns false' do
      expect(eventable).to receive(:callback)

      eventable.notify_of_event!('test.unless-symbol-args.false')
    end
  end

  context 'when using mutual exclusive locks' do
    it 'should notify for as many events as possible' do
      expect(eventable).to receive(:callback).at_most(16).times

      threads = []

      32.times do
        threads << Thread.new { eventable.notify_of_event!('test.exclusive-event') }
      end

      threads.map(&:join)
    end

    it 'should wait and notify for all events' do
      expect(eventable).to receive(:callback).exactly(32).times

      threads = []

      32.times do
        threads << Thread.new { eventable.notify_of_event!('test.exclusive-event.wait-and-raise') }
      end

      threads.map(&:join)
    end

    it 'should raise when an event is locked' do
      threads = []
      threads << Thread.new { expect { eventable.notify_of_event!('test.exclusive-event.raise') }.to_not raise_error }
      threads << Thread.new do
        sleep 0.5.seconds

        expect { eventable.notify_of_event!('test.exclusive-event.raise') }.to raise_error Envented::LockNotAcquiredError
      end

      threads.map(&:join)
    end

    it 'should raise on event lock timeout' do
      threads = []
      threads << Thread.new { expect { eventable.notify_of_event!('test.exclusive-event.timeout') }.to_not raise_error }
      threads << Thread.new do
        sleep 0.5.seconds

        expect { eventable.notify_of_event!('test.exclusive-event.timeout') }.to raise_error Envented::LockTimeoutError
      end

      threads.map(&:join)
    end

    it 'should notify for an event once' do
      expect(eventable).to receive(:callback).once

      threads = []

      # FIXME(ezekg) This should probably be physical core count?
      4.times do |i|
        threads << Thread.new { eventable.notify_of_event!('test.exclusive-event.once') }
      end

      threads.map(&:join)
    end
  end
end
