# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe AsyncDestroyable, type: :concern do
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
    include AsyncDestroyable
  end

  describe '#destroy_async' do
    it 'enqueues a DestroyAsyncJob' do
      person = Person.create!(name: 'test')

      expect { person.destroy_async }
        .to have_enqueued_job(AsyncDestroyable::DestroyAsyncJob)
    end

    it 'destroys the record when job is performed' do
      person = Person.create!(name: 'test')

      expect {
        perform_enqueued_jobs { person.destroy_async }
      }.to change(Person, :count).by(-1)
    end
  end

  describe AsyncDestroyable::DestroyAsyncJob do
    it 'destroys the record' do
      person = Person.create!(name: 'test')

      expect {
        described_class.perform_now(class_name: Person.name, id: person.id)
      }.to change(Person, :count).by(-1)
    end

    it 'does nothing if record is missing' do
      expect {
        described_class.perform_now(class_name: Person.name, id: SecureRandom.uuid)
      }.to_not raise_error
    end
  end
end
