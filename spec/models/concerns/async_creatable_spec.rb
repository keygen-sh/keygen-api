# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe AsyncCreatable, type: :concern do
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
    include AsyncCreatable
  end

  describe '.create_async' do
    it 'enqueues a CreateAsyncJob' do
      expect { Person.create_async(name: 'test') }
        .to have_enqueued_job(AsyncCreatable::CreateAsyncJob)
    end

    it 'creates the record when job is performed' do
      expect {
        perform_enqueued_jobs { Person.create_async(name: 'test') }
      }.to change(Person, :count).by(1)

      expect(Person.last.name).to eq 'test'
    end
  end

  describe AsyncCreatable::CreateAsyncJob do
    it 'creates a record with the given attributes' do
      expect {
        described_class.perform_now(class_name: Person.name, attributes: { 'name' => 'test' })
      }.to change(Person, :count).by(1)
    end

    it 'discards on deserialization error' do
      expect {
        described_class.perform_now(class_name: 'NonExistentClass', attributes: {})
      }.to raise_error(NameError)
    end
  end
end
