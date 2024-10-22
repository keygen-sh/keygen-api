# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe WaitForArtifactUploadWorker do
  let(:account)  { create(:account) }
  let(:waiter)   { WaitForArtifactUploadWorker }
  let(:notifier) { NotifyArtifactUploadWorker }

  context 'when an artifact is waiting' do
    let(:artifact) { create(:release_artifact, :waiting, account:) }

    before do
      Aws.config[:s3] = { stub_responses: { head_object: [{ content_length: 420, content_type: 'application/octet-stream', etag: '"14bfa6bb14875e45bba028a21ed38046"' }] } }
    end

    after do
      notifier.clear
      waiter.clear
    end

    context 'when an upload succeeds' do
      it 'should emit an artifact.upload.succeeded event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.processing') }.exactly(1).time
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: %w[artifact.upload.succeeded artifact.uploaded]) }.exactly(1).time

        waiter.perform_async(artifact.id)
        waiter.drain

        notifier.drain
      end

      it 'should have an uploaded status' do
        waiter.perform_async(artifact.id)

        expect { waiter.drain   }.to change { artifact.reload.status }.from('WAITING').to 'PROCESSING'
        expect { notifier.drain }.to change { artifact.reload.status }.to 'UPLOADED'
      end

      it 'should store object metadata' do
        waiter.perform_async(artifact.id)

        expect { waiter.drain }.to change { artifact.reload.updated_at }

        artifact.reload

        expect(artifact.content_length).to eq 420
        expect(artifact.content_type).to eq 'application/octet-stream'
        expect(artifact.etag).to eq '14bfa6bb14875e45bba028a21ed38046'
      end
    end

    context 'when an upload fails' do
      before do
        Aws.config[:s3][:stub_responses][:head_object] = [Aws::Waiters::Errors::WaiterFailed]
      end

      it 'should emit an artifact.upload.failed event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.failed') }.exactly(1).time

        waiter.perform_async(artifact.id)
        waiter.drain

        notifier.drain
      end

      it 'should have an failed status' do
        waiter.perform_async(artifact.id)

        expect { waiter.drain   }.to not_change { artifact.reload.status }
        expect { notifier.drain }.to change     { artifact.reload.status }.from('WAITING').to 'FAILED'
      end
    end

    context 'when artifact is a valid gem' do
      let(:artifact)  { create(:artifact, :rubygems, :waiting, account:) }
      let(:processor) { ProcessGemSpecificationWorker }

      before do
        Aws.config[:s3][:stub_responses][:get_object] = [{ body: file_fixture('ping-1.0.0.gem').open }]
      end

      after do
        processor.clear
      end

      it 'should emit an artifact.upload.processing event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.processing') }.exactly(1).time
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: %w[artifact.upload.succeeded artifact.uploaded]) }.exactly(1).time

        waiter.perform_async(artifact.id)
        waiter.drain
        processor.drain
        notifier.drain
      end

      it 'should process gem' do
        waiter.perform_async(artifact.id)

        expect { waiter.drain }.to change { processor.jobs.size }.from(0).to(1)
          .and change { artifact.reload.status }.from('WAITING').to('PROCESSING')
          .and change { notifier.jobs.size }.from(0).to(1)

        expect { notifier.drain }.to not_change { artifact.reload.status }

        expect { processor.drain }.to change { notifier.jobs.size }.from(0).to(1)
          .and not_change { artifact.reload.status }

        expect { notifier.drain }.to change { artifact.reload.status }.from('PROCESSING').to('UPLOADED')

        expect(artifact.reload.specification).to_not be nil
      end
    end

    context 'when artifact is an invalid gem' do
      let(:artifact)  { create(:artifact, :rubygems, :waiting, account:) }
      let(:processor) { ProcessGemSpecificationWorker }

      before do
        Aws.config[:s3][:stub_responses][:get_object] = [{ body: file_fixture('invalid-1.0.0.gem').open }]
      end

      after do
        processor.clear
      end

      it 'should emit an artifact.upload.processing event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.processing') }.exactly(1).time
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.failed') }.exactly(1).time

        waiter.perform_async(artifact.id)
        waiter.drain
        processor.drain
        notifier.drain
      end

      it 'should not process gem' do
        waiter.perform_async(artifact.id)

        expect { waiter.drain }.to change { processor.jobs.size }.from(0).to(1)
          .and change { artifact.reload.status }.from('WAITING').to('PROCESSING')
          .and change { notifier.jobs.size }.from(0).to(1)

        expect { notifier.drain }.to not_change { artifact.reload.status }

        expect { processor.drain }.to change { notifier.jobs.size }.from(0).to(1)
          .and not_change { artifact.reload.status }

        expect { notifier.drain }.to change { artifact.reload.status }.from('PROCESSING').to('FAILED')

        expect(artifact.reload.specification).to be nil
      end
    end
  end

  context 'when an artifact is uploaded' do
    let(:artifact) { create(:release_artifact, :uploaded, account:) }

    it 'should enqueue and skip the worker' do
      waiter.perform_async(artifact.id)

      expect { waiter.drain }.to not_change { artifact.reload.updated_at }
        .and not_change { notifier.jobs.size }
    end
  end

  context 'when an artifact is failed' do
    let(:artifact) { create(:release_artifact, :failed, account:) }

    it 'should enqueue and skip the worker' do
      waiter.perform_async(artifact.id)

      expect { waiter.drain }.to not_change { artifact.reload.updated_at }
        .and not_change { notifier.jobs.size }
    end
  end
end
