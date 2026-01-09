# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe AsyncTouchable, type: :concern do
  around do |example|
    adapter_was, ActiveJob::Base.queue_adapter = ActiveJob::Base.queue_adapter, :test

    example.run
  ensure
    ActiveJob::Base.queue_adapter = adapter_was
  end

  temporary_table :people do |t|
    t.string :name
    t.datetime :last_seen_at
    t.timestamps
  end

  temporary_model :person, table_name: :people do
    include AsyncTouchable
  end

  describe '#touch_async' do
    it 'enqueues a TouchAsyncJob' do
      person = Person.create!(name: 'test')

      expect { person.touch_async }.to(
        have_enqueued_job(AsyncTouchable::TouchAsyncJob),
      )
    end

    it 'touches the record when job is performed' do
      person         = Person.create!(name: 'test')
      updated_at_was = person.updated_at

      travel_to 1.minute.from_now do
        perform_enqueued_jobs { person.touch_async }
      end

      expect(person.reload.updated_at).to be > updated_at_was
    end

    it 'touches specific columns' do
      person = Person.create!(name: 'test')
      expect(person.last_seen_at).to be_nil

      perform_enqueued_jobs { person.touch_async(:last_seen_at) }

      expect(person.reload.last_seen_at).to_not be_nil
    end

    it 'discards stale touches' do
      person         = Person.create!(name: 'test')
      updated_at_was = person.updated_at

      # simulate a more recent update
      person.update!(name: 'updated')
      newer_updated_at = person.updated_at

      # now perform the stale touch job
      AsyncTouchable::TouchAsyncJob.perform_now(
        class_name: Person.name,
        id: person.id,
        names: [],
        time: nil,
        last_updated_at: updated_at_was,
      )

      expect(person.reload.updated_at).to eq newer_updated_at
    end
  end

  describe '#touch_async!' do
    it 'enqueues a TouchAsyncJob' do
      person = Person.create!(name: 'test')

      expect { person.touch_async! }.to(
        have_enqueued_job(AsyncTouchable::TouchAsyncJob),
      )
    end

    it 'applies timestamps optimistically' do
      person         = Person.create!(name: 'test')
      updated_at_was = person.updated_at

      travel_to 1.minute.from_now do
        person.touch_async!
      end

      expect(person.updated_at).to be > updated_at_was
    end

    it 'applies specific columns optimistically' do
      person = Person.create!(name: 'test')

      expect(person.last_seen_at).to be_nil

      person.touch_async!(:last_seen_at)

      expect(person.last_seen_at).to_not be_nil
    end

    it 'marks the record as readonly' do
      person = Person.create!(name: 'test')

      person.touch_async!

      expect(person).to be_readonly
    end

    it 'touches the record when job is performed' do
      person         = Person.create!(name: 'test')
      updated_at_was = person.updated_at

      travel_to 1.minute.from_now do
        perform_enqueued_jobs { person.touch_async! }
      end

      expect(person.reload.updated_at).to be > updated_at_was
    end
  end

  describe AsyncTouchable::TouchAsyncJob do
    it 'touches the record' do
      person         = Person.create!(name: 'test')
      updated_at_was = person.updated_at

      travel_to 1.minute.from_now do
        described_class.perform_now(
          class_name: Person.name,
          id: person.id,
          names: [],
          time: nil,
          last_updated_at: person.updated_at,
        )
      end

      expect(person.reload.updated_at).to be > updated_at_was
    end

    it 'does nothing if record is missing' do
      expect {
        described_class.perform_now(
          class_name: Person.name,
          id: SecureRandom.uuid,
          names: [],
          time: nil,
          last_updated_at: Time.current,
        )
      }.to_not raise_error
    end

    it 'touches with a specific time' do
      person = Person.create!(name: 'test')
      time   = 1.hour.from_now

      described_class.perform_now(
        class_name: Person.name,
        id: person.id,
        names: [],
        time:,
        last_updated_at: person.updated_at,
      )

      expect(person.reload.updated_at).to be_within(1.second).of(time)
    end
  end
end
