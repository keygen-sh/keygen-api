# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require 'rubygems/package'

describe ProcessRubyGemWorker do
  let(:account) { create(:account) }

  subject { described_class }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  context 'when artifact is a valid gem' do
    let(:gem)     { file_fixture('ping-1.0.0.gem').open }
    let(:gemspec) { Gem::Package.new(gem).spec }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: gem }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :gem, :waiting, account:) }

      it 'should do nothing' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'WAITING'
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :gem, :processing, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to change { artifact.reload.manifest }

        expect(artifact.manifest.content_type).to eq 'application/x-yaml'
        expect(artifact.manifest.content_path).to eq gemspec.file_name
        expect(artifact.manifest.content).to eq gemspec.to_yaml
        expect(artifact.status).to eq 'UPLOADED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :gem, :uploaded, account:) }

      it 'should do nothing' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'UPLOADED'
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :gem, :failed, account:) }

      it 'should do nothing' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'FAILED'
      end
    end
  end

  context 'when artifact is an invalid gem' do
    let(:gem) { file_fixture('invalid-1.0.0.gem').open }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: gem }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :gem, :waiting, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :gem, :processing, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :gem, :uploaded, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :gem, :failed, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end
  end

  context 'when artifact is not a gem' do
    let(:noise) { Random.bytes(1.megabyte) }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: noise }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :waiting, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :processing, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :uploaded, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :failed, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end
  end

  context 'when artifact is too big' do
    let(:noise) { Random.bytes(1.kilobyte) }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: noise }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :waiting, filesize: 1.gigabyte, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :processing, filesize: 1.gigabyte, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :uploaded, filesize: 1.gigabyte, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :failed, filesize: 1.gigabyte, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end
  end

  context 'when artifact is too small' do
    let(:noise) { Random.bytes(1.kilobyte) }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: noise }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :waiting, content_length: 0, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'WAITING'
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :processing, content_length: 0, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :uploaded, content_length: 0, account:) }

      it 'should not process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'UPLOADED'
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :failed, content_length: 0, account:) }

      it 'should not process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'FAILED'
      end
    end
  end
end
