# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe WaitForArtifactUploadWorker do
  let(:worker)  { WaitForArtifactUploadWorker }
  let(:account) { create(:account) }

  context 'when an artifact is waiting' do
    let(:artifact) { create(:release_artifact, :waiting, account:) }
    let(:event)    { 'artifact.uploaded' }

    before do
      Aws.config[:s3] = { stub_responses: { head_object: [{ content_length: 420, content_type: 'application/octet-stream', etag: '"14bfa6bb14875e45bba028a21ed38046"' }] } }
    end

    it 'should enqueue and run the worker' do
      worker.perform_async(artifact.id)
      expect(worker.jobs.size).to eq 1

      worker.drain
      expect(worker.jobs.size).to eq 0
    end

    context 'when an upload succeeds' do
      it 'should emit an artifact.uploaded event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

        worker.perform_async(artifact.id)
        worker.drain
      end

      it 'should have an uploaded status' do
        worker.perform_async(artifact.id)
        worker.drain

        expect(artifact.reload.status).to eq 'UPLOADED'
      end

      it 'should store object metadata' do
        worker.perform_async(artifact.id)
        worker.drain

        artifact.reload

        expect(artifact.content_length).to eq 420
        expect(artifact.content_type).to eq 'application/octet-stream'
        expect(artifact.etag).to eq '14bfa6bb14875e45bba028a21ed38046'
      end
    end

    context 'when an upload fails' do
      before do
        Aws.config[:s3] = { stub_responses: { head_object: [Aws::Waiters::Errors::WaiterFailed] } }
      end

      it 'should not emit an artifact.uploaded event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(0).times

        worker.perform_async(artifact.id)
        worker.drain
      end

      it 'should have an failed status' do
        worker.perform_async(artifact.id)
        worker.drain

        expect(artifact.reload.status).to eq 'FAILED'
      end
    end
  end

  context 'when an artifact is uploaded' do
    let(:artifact) { create(:release_artifact, :uploaded, account:) }

    it 'should enqueue and skip the worker' do
      worker.perform_async(artifact.id)
      expect(worker.jobs.size).to eq 1

      worker.drain
      expect(worker.jobs.size).to eq 0
    end
  end

  context 'when an artifact is failed' do
    let(:artifact) { create(:release_artifact, :failed, account:) }

    it 'should enqueue and skip the worker' do
      worker.perform_async(artifact.id)
      expect(worker.jobs.size).to eq 1

      worker.drain
      expect(worker.jobs.size).to eq 0
    end
  end
end
