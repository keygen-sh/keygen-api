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
    t.string :email
    t.string :name
    t.timestamps
  end

  temporary_model :person, table_name: :people do
    include AsyncUpdatable
  end

  describe '#update_async' do
    it 'enqueues an UpdateAsyncJob' do
      person = Person.create!(name: 'test')

      expect { person.update_async(name: 'updated') }.to(
        have_enqueued_job(AsyncUpdatable::UpdateAsyncJob),
      )
    end

    it 'updates the record when job is performed' do
      person = Person.create!(name: 'test')

      perform_enqueued_jobs { person.update_async(name: 'updated') }

      expect(person.reload.name).to eq 'updated'
    end

    it 'includes dirty attributes in the update' do
      person = Person.create!(name: 'test', email: 'test@keygen.example')

      person.email = 'updated@keygen.example'

      perform_enqueued_jobs { person.update_async(name: 'updated') }

      person.reload

      expect(person.email).to eq 'updated@keygen.example'
      expect(person.name).to eq 'updated'
    end

    it 'only updates changed attributes' do
      person = Person.create!(name: 'test', email: 'test@keygen.example')

      person.email = 'updated@keygen.example'

      expect { person.update_async(name: 'updated') }.to have_enqueued_job(
        AsyncUpdatable::UpdateAsyncJob,
      ).with(
        class_name: 'Person',
        id: person.id,
        attributes: { 'email' => 'updated@keygen.example', 'name' => 'updated' },
      )
    end
  end

  describe '#update_async!' do
    it 'enqueues an UpdateAsyncJob' do
      person = Person.create!(name: 'test')

      expect { person.update_async!(name: 'updated') }.to(
        have_enqueued_job(AsyncUpdatable::UpdateAsyncJob),
      )
    end

    it 'applies attributes optimistically' do
      person = Person.create!(name: 'test')

      person.update_async!(name: 'updated')

      expect(person.name).to eq 'updated'
    end

    it 'marks the record as readonly' do
      person = Person.create!(name: 'test')

      person.update_async!(name: 'updated')

      expect(person).to be_readonly
    end

    it 'updates the record when job is performed' do
      person = Person.create!(name: 'test')

      perform_enqueued_jobs { person.update_async!(name: 'updated') }

      expect(person.reload.name).to eq 'updated'
    end
  end

  describe AsyncUpdatable::UpdateAsyncJob do
    it 'updates the record' do
      person = Person.create!(name: 'test')

      described_class.perform_now(
        class_name: Person.name,
        id: person.id,
        attributes: { 'name' => 'updated' },
      )

      expect(person.reload.name).to eq 'updated'
    end

    it 'does nothing if record is missing' do
      expect {
        described_class.perform_now(
          class_name: Person.name,
          id: SecureRandom.uuid,
          attributes: { 'name' => 'updated' },
        )
      }.to_not raise_error
    end
  end
end
