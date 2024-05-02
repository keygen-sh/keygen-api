# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe EventLog, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#event_type=' do
    let(:event_type) { create(:event_type) }

    context 'on build' do
      it 'should denormalize event from event type' do
        event_log = build(:event_log, event_type:, account:)

        expect(event_log.event_type_event).to eq event_type.event
        expect(event_log.event_type_id).to eq event_type.id
      end

      it 'should denormalize event type to request log' do
        request_log = build(:request_log, account:)
        event_log   = build(:event_log, request_log:, event_type:, account:)

        expect(request_log.event_type_event).to be_nil
        expect(request_log.event_type_id).to eq event_type.id
      end
    end

    context 'on create' do
      it 'should denormalize event from event type' do
        event_log = create(:event_log, event_type:, account:)

        expect(event_log.event_type_event).to eq event_type.event
        expect(event_log.event_type_id).to eq event_type.id
      end

      it 'should denormalize event type to request log' do
        request_log = create(:request_log, account:)
        event_log   = create(:event_log, request_log:, event_type:, account:)

        request_log.reload

        expect(request_log.event_type_event).to eq event_type.event
        expect(request_log.event_type_id).to eq event_type.id
      end
    end

    context 'on update' do
      it 'should denormalize event from event type' do
        event_log = create(:event_log, account:)

        event_log.update!(event_type:)

        expect(event_log.event_type_event).to eq event_type.event
        expect(event_log.event_type_id).to eq event_type.id
      end

      it 'should denormalize event type to request log' do
        request_log = create(:request_log, account:)
        event_log   = create(:event_log, request_log:, account:)

        event_log.update!(event_type:)
        request_log.reload

        expect(request_log.event_type_event).to eq event_type.event
        expect(request_log.event_type_id).to eq event_type.id
      end
    end
  end
end
