# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'rubygems/package'

describe ProcessGemSpecificationWorker do
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
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :rubygems, :processing, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to change { artifact.reload.specification }

        expect(artifact.specification.content).to eq gemspec.to_yaml
        expect(artifact.status).to eq 'UPLOADED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :rubygems, :uploaded, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :rubygems, :failed, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }
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
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :rubygems, :processing, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }

        expect(artifact.specification).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :rubygems, :uploaded, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :rubygems, :failed, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }
      end
    end
  end

  context 'when artifact is not a gem' do
    let(:gem) { SecureRandom.bytes(1.megabyte) }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: gem }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :rubygems, :waiting, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :rubygems, :processing, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }

        expect(artifact.specification).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :rubygems, :uploaded, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :rubygems, :failed, account:) }

      it 'should process gem' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.specification }
      end
    end
  end
end
