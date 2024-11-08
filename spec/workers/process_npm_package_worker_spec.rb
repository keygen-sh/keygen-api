# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require 'minitar'
require 'zlib'

describe ProcessNpmPackageWorker do
  let(:account) { create(:account) }

  subject { described_class }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  context 'when artifact is a valid package' do
    let(:package)      { file_fixture('hello-2.0.0.tgz').open }
    let(:package_json) {
      tar  = Zlib::GzipReader.new(package)
      json = Minitar::Reader.open tar do |archive|
        archive.find { _1.file? && _1.name in 'package/package.json' }
               .read
      end

      json
    }

    let(:minified_package_json) {
      JSON.parse(package_json)
          .to_json
    }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: package }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :npm_package, :waiting, account:) }

      it 'should do nothing' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'WAITING'
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :npm_package, :processing, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to change { artifact.reload.manifest }

        expect(artifact.manifest.content).to eq minified_package_json
        expect(artifact.status).to eq 'UPLOADED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :npm_package, :uploaded, account:) }

      it 'should do nothing' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'UPLOADED'
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :npm_package, :failed, account:) }

      it 'should do nothing' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'FAILED'
      end
    end
  end

  context 'when artifact is an invalid package' do
    let(:package) { file_fixture('invalid-2.0.0.tgz').open }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: package }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :npm_package, :waiting, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :npm_package, :processing, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :npm_package, :uploaded, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :npm_package, :failed, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end
  end

  context 'when artifact is not a package' do
    let(:noise) { Random.bytes(1.megabyte) }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: noise }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :waiting, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :processing, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :uploaded, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :failed, account:) }

      it 'should process package' do
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

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :processing, filesize: 1.gigabyte, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :uploaded, filesize: 1.gigabyte, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :failed, filesize: 1.gigabyte, account:) }

      it 'should process package' do
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

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'WAITING'
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :processing, content_length: 0, account:) }

      it 'should process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :uploaded, content_length: 0, account:) }

      it 'should not process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'UPLOADED'
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :failed, content_length: 0, account:) }

      it 'should not process package' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'FAILED'
      end
    end
  end

  context 'when artifact filesize is unaccurate' do
    let(:artifact) { create(:artifact, :processing, filesize: 1.kilobyte, account:) }
    let(:file)     { file_fixture('large.tar.gz').open }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: file }] } } }
    end

    it 'should not process file' do
      expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

      expect(artifact.status).to eq 'FAILED'
    end

    it 'should be efficient' do
      expect { subject.perform_async(artifact.id) }.to allocate_less_than(5.megabytes)
    end
  end
end
