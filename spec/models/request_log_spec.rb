# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RequestLog, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#event_type=' do
    let(:event_type) { create(:event_type) }

    context 'on build' do
      it 'should denormalize event from event type' do
        request_log = build(:request_log, event_type:, account:)

        expect(request_log.event_type_event).to eq event_type.event
      end
    end

    context 'on create' do
      it 'should denormalize event from event type' do
        request_log = create(:request_log, event_type:, account:)

        expect(request_log.event_type_event).to eq event_type.event
      end
    end

    context 'on update' do
      it 'should denormalize event from event type' do
        request_log = create(:request_log, account:)

        request_log.update!(event_type:)

        expect(request_log.event_type_event).to eq event_type.event
      end
    end
  end
end
