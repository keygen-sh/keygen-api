# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe WaitForArtifactUploadWorker do
  let(:account) { create(:account) }

  subject { described_class }

  context 'when an artifact is waiting' do
    let(:artifact) { create(:artifact, :waiting, account:) }

    before do
      Aws.config[:s3] = { stub_responses: { head_object: [{ content_length: 420, content_type: 'application/octet-stream', etag: '"14bfa6bb14875e45bba028a21ed38046"' }] } }
    end

    after do
      subject.clear
    end

    context 'when an upload succeeds' do
      it 'should emit success events' do
        # double event is for backwards compat
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: %w[artifact.upload.succeeded artifact.uploaded]) }.exactly(1).time

        subject.perform_async(artifact.id)
        subject.drain
      end

      it 'should have an uploaded status' do
        subject.perform_async(artifact.id)

        expect { subject.drain }.to change { artifact.reload.status }.from('WAITING').to 'UPLOADED'
      end

      it 'should store object metadata' do
        subject.perform_async(artifact.id)

        expect { subject.drain }.to change { artifact.reload.updated_at }

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

      it 'should emit a failed event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.failed') }.exactly(1).time

        subject.perform_async(artifact.id)
        subject.drain
      end

      it 'should have an failed status' do
        subject.perform_async(artifact.id)

        expect { subject.drain }.to change { artifact.reload.status }.from('WAITING').to 'FAILED'
      end
    end

    context 'when artifact is a gem' do
      let(:artifact)  { create(:artifact, :gem, :waiting, account:) }
      let(:processor) { ProcessRubyGemWorker }

      before do
        Aws.config[:s3][:stub_responses][:get_object] = [{ body: file_fixture('ping-1.0.0.gem').open }]
      end

      after do
        processor.clear
      end

      it 'should emit processing and succeeded events' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.processing') }.exactly(1).time
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.succeeded') }.exactly(1).time

        subject.perform_async(artifact.id)
        subject.drain

        processor.drain
      end

      it 'should process gem' do
        subject.perform_async(artifact.id)

        expect { subject.drain }.to change { processor.jobs.size }.from(0).to(1)
          .and change { artifact.reload.status }.from('WAITING').to('PROCESSING')

        expect { processor.drain }.to change { artifact.reload.status }.from('PROCESSING').to('UPLOADED')

        expect(artifact.reload.manifest).to_not be nil
      end

      context 'when gem is invalid' do
        let(:artifact)  { create(:artifact, :gem, :waiting, account:) }
        let(:processor) { ProcessRubyGemWorker }

        before do
          Aws.config[:s3][:stub_responses][:get_object] = [{ body: file_fixture('invalid-1.0.0.gem').open }]
        end

        after do
          processor.clear
        end

        it 'should emit processing and failed events' do
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.processing') }.exactly(1).time
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.failed') }.exactly(1).time

          subject.perform_async(artifact.id)
          subject.drain

          processor.drain
        end

        it 'should fail processing gem' do
          subject.perform_async(artifact.id)

          expect { subject.drain }.to change { processor.jobs.size }.from(0).to(1)
            .and change { artifact.reload.status }.from('WAITING').to('PROCESSING')

          expect { processor.drain }.to change { artifact.reload.status }.from('PROCESSING').to('FAILED')

          expect(artifact.reload.manifest).to be nil
        end
      end

      context 'when gem is too small' do
        let(:artifact)  { create(:artifact, :gem, :waiting, account:) }
        let(:processor) { ProcessRubyGemWorker }

        before do
          Aws.config[:s3] = {
            stub_responses: {
              head_object: [{ content_length: 2.bytes.to_i, content_type: 'application/octet-stream', etag: '"14bfa6bb14875e45bba028a21ed38046"' }],
              get_object: [{ body: file_fixture('ping-1.0.0.gem').open }],
            },
          }
        end

        after do
          processor.clear
        end

        it 'should emit processing and failed events' do
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.processing') }.exactly(1).time
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.failed') }.exactly(1).time

          subject.perform_async(artifact.id)
          subject.drain

          processor.drain
        end

        it 'should fail processing gem' do
          subject.perform_async(artifact.id)

          expect { subject.drain }.to change { processor.jobs.size }.from(0).to(1)
            .and change { artifact.reload.status }.from('WAITING').to('PROCESSING')

          expect { processor.drain }.to change { artifact.reload.status }.from('PROCESSING').to('FAILED')

          expect(artifact.reload.manifest).to be nil
        end
      end

      context 'when gem is too large' do
        let(:artifact)  { create(:artifact, :gem, :waiting, account:) }
        let(:processor) { ProcessRubyGemWorker }

        before do
          Aws.config[:s3] = {
            stub_responses: {
              head_object: [{ content_length: 1.gigabyte.to_i, content_type: 'application/octet-stream', etag: '"14bfa6bb14875e45bba028a21ed38046"' }],
              get_object: [{ body: file_fixture('ping-1.0.0.gem').open }],
            },
          }
        end

        after do
          processor.clear
        end

        it 'should emit processing and succeeded events' do
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.processing') }.exactly(1).time
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event: 'artifact.upload.failed') }.exactly(1).time

          subject.perform_async(artifact.id)
          subject.drain

          processor.drain
        end

        it 'should fail processing gem' do
          subject.perform_async(artifact.id)

          expect { subject.drain }.to change { processor.jobs.size }.from(0).to(1)
            .and change { artifact.reload.status }.from('WAITING').to('PROCESSING')

          expect { processor.drain }.to change { artifact.reload.status }.from('PROCESSING').to('FAILED')

          expect(artifact.reload.manifest).to be nil
        end
      end
    end
  end

  context 'when an artifact is processing' do
    let(:artifact) { create(:artifact, :processing, account:) }

    it 'should emit no events' do
      expect(BroadcastEventService).to receive(:call).exactly(0).times

      subject.perform_async(artifact.id)
      subject.drain
    end

    it 'should do nothing' do
      subject.perform_async(artifact.id)

      expect { subject.drain }.to not_change { artifact.reload.updated_at }
    end
  end

  context 'when an artifact is uploaded' do
    let(:artifact) { create(:artifact, :uploaded, account:) }

    it 'should emit no events' do
      expect(BroadcastEventService).to receive(:call).exactly(0).times

      subject.perform_async(artifact.id)
      subject.drain
    end

    it 'should emit no events' do
      expect(BroadcastEventService).to receive(:call).exactly(0).times

      subject.perform_async(artifact.id)
      subject.drain
    end

    it 'should do nothing' do
      subject.perform_async(artifact.id)

      expect { subject.drain }.to not_change { artifact.reload.updated_at }
    end
  end

  context 'when an artifact is failed' do
    let(:artifact) { create(:artifact, :failed, account:) }

    it 'should emit no events' do
      expect(BroadcastEventService).to receive(:call).exactly(0).times

      subject.perform_async(artifact.id)
      subject.drain
    end

    it 'should emit no events' do
      expect(BroadcastEventService).to receive(:call).exactly(0).times

      subject.perform_async(artifact.id)
      subject.drain
    end

    it 'should do nothing' do
      subject.perform_async(artifact.id)

      expect { subject.drain }.to not_change { artifact.reload.updated_at }
    end
  end
end
