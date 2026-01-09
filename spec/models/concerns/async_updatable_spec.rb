# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe AsyncUpdatable, type: :concern do
  around do |example|
    adapter_was, ActiveJob::Base.queue_adapter = ActiveJob::Base.queue_adapter, :test

    example.run
  ensure
    ActiveJob::Base.queue_adapter = adapter_was
  end

  temporary_table :people do |t|
    t.string :name
    t.timestamps
  end

  temporary_model :person, table_name: :people do
    include AsyncUpdatable
  end

  describe '#update_async' do
    it 'enqueues an UpdateAsyncJob' do
      person = Person.create!(name: 'test')

      expect { person.update_async(name: 'updated') }
        .to have_enqueued_job(AsyncUpdatable::UpdateAsyncJob)
    end

    it 'updates the record when job is performed' do
      person = Person.create!(name: 'test')

      perform_enqueued_jobs { person.update_async(name: 'updated') }

      expect(person.reload.name).to eq 'updated'
    end

    it 'discards stale updates' do
      person         = Person.create!(name: 'test')
      updated_at_was = person.updated_at

      # simulate a more recent update
      person.update!(name: 'newer')

      # now perform the stale job
      AsyncUpdatable::UpdateAsyncJob.perform_now(
        class_name: Person.name,
        id: person.id,
        attributes: { 'name' => 'stale' },
        last_updated_at: updated_at_was,
      )

      expect(person.reload.name).to eq 'newer'
    end
  end

  describe AsyncUpdatable::UpdateAsyncJob do
    it 'updates the record' do
      person = Person.create!(name: 'test')

      described_class.perform_now(
        class_name: Person.name,
        id: person.id,
        attributes: { 'name' => 'updated' },
        last_updated_at: person.updated_at,
      )

      expect(person.reload.name).to eq 'updated'
    end

    it 'does nothing if record is missing' do
      person = Person.create!(name: 'test')

      expect {
        described_class.perform_now(
          class_name: Person.name,
          id: SecureRandom.uuid,
          attributes: { 'name' => 'updated' },
          last_updated_at: Time.current,
        )
      }.to_not raise_error
    end

    it 'discards stale updates based on updated_at' do
      person   = Person.create!(name: 'test')
      old_time = 1.hour.ago

      described_class.perform_now(
        class_name: Person.name,
        id: person.id,
        attributes: { 'name' => 'stale' },
        last_updated_at: old_time,
      )

      expect(person.reload.name).to eq 'test'
    end
  end
end
