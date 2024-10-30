# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'rubygems/package'

describe ProcessRubyGemWorker do
  let(:account)  { create(:account) }

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
      let(:artifact) { create(:artifact, :rubygems, :waiting, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :rubygems, :processing, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to change { artifact.reload.manifest }

        expect(artifact.manifest.content).to eq gemspec.to_yaml
        expect(artifact.status).to eq 'UPLOADED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :rubygems, :uploaded, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :rubygems, :failed, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end
  end

  context 'when artifact is an invalid gem' do
    let(:gem) { file_fixture('invalid-1.0.0.gem').open }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: gem }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :rubygems, :waiting, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :rubygems, :processing, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :rubygems, :uploaded, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :rubygems, :failed, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end
  end

  context 'when artifact is not a gem' do
    let(:file) { SecureRandom.bytes(1.megabyte) }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: file }] } } }
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
end
