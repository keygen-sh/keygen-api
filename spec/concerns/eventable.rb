require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, {
  except: ['event_types']
}

describe Eventable do
  let(:eventable) do
    klass = Struct.new(:id) do
      include ActiveModel::Model
      include Eventable

      attr_accessor :has_been_called_once

      on_locked_event 'test.exclusive-event', :callback

      on_locked_event 'test.exclusive-event.wait-and-raise', :callback,
        raise_on_lock_error: true,
        wait_on_lock: true

      on_locked_event 'test.exclusive-event.raise', :callback,
        raise_on_lock_error: true

      on_locked_event 'test.exclusive-event.wait', :callback,
        wait_on_lock: true

      on_locked_event 'test.exclusive-event.once', :callback,
        unless: :has_been_called_once?

      on_event 'test.event',    :callback
      on_event 'test-suffix.*', :callback
      on_event '*.test-prefix', :callback

      private

      def has_been_called_once?
        @has_been_called_once
      end

      def callback
        @has_been_called_once = true

        sleep 0.1
      end
    end

    klass.new(id: SecureRandom.uuid)
  end

  it 'should invoke a callback on a valid event' do
    expect(eventable).to receive(:callback).once

    eventable.notify_of_event!('test.event')
  end

  it 'should not invoke a callback on an invalid event' do
    expect(eventable).to_not receive(:callback)

    eventable.notify_of_event!('foo.bar')
  end

  it 'should invoke a callback on a wildcard suffix event' do
    expect(eventable).to receive(:callback).once

    eventable.notify_of_event!('test-suffix.foo')
  end

  it 'should invoke a callback on a wildcard prefix event' do
    expect(eventable).to receive(:callback).once

    eventable.notify_of_event!('foo.test-prefix')
  end

  it 'should not invoke a callback on a duplicate idempotency key' do
    expect(eventable).to receive(:callback).once

    key = SecureRandom.hex

    eventable.notify_of_event!('test.event', idempotency_key: key)
    eventable.notify_of_event!('test.event', idempotency_key: key)
  end

  context 'mutual exclusivity locks' do
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

    skip 'should raise when an event is locked' do
      expect(eventable).to receive(:callback).once

      threads = []

      # FIXME(ezekg) How do I reliably test this?
      threads << Thread.new { expect { eventable.notify_of_event!('test.exclusive-event.raise') }.to_not raise_error Eventable::LockNotAcquiredError }
      threads << Thread.new { expect { eventable.notify_of_event!('test.exclusive-event.raise') }.to raise_error Eventable::LockNotAcquiredError }

      threads.map(&:join)
    end

    it 'should notify for an event once' do
      expect(eventable).to receive(:callback).once

      threads = []

      4.times do |i|
        threads << Thread.new { eventable.notify_of_event!('test.exclusive-event.once') }
      end

      threads.map(&:join)
    end
  end
end
