# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require 'minitar'
require 'zlib'

describe ProcessOciImageWorker do
  let(:account) { create(:account) }

  subject { described_class }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  context 'when artifact is a valid image' do
    let(:image_fixture) { 'alpine-3.20.3.tar' }
    let(:image_tarball) { file_fixture(image_fixture).open }
    let(:image_index) {
      tarball = file_fixture(image_fixture).open

      Minitar::Reader.open tarball do |archive|
        archive.find { _1.file? && _1.name in 'index.json' }
               .read
      end
    }

    let(:minified_image_index) {
      JSON.parse(image_index)
          .to_json
    }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: image_tarball }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :oci_image, :waiting, account:) }

      it 'should not store manifest' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'WAITING'
      end

      it 'should not upload blobs' do
        expect { subject.perform_async(artifact.id) }.to_not upload
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :oci_image, :processing, account:) }

      it 'should store manifest' do
        expect { subject.perform_async(artifact.id) }.to change { artifact.reload.manifest }

        expect(artifact.manifest.content).to eq minified_image_index
        expect(artifact.status).to eq 'UPLOADED'
      end

      context 'when blobs are not uploaded' do
        before do
          Aws.config[:s3][:stub_responses][:head_object] = [Aws::S3::Errors::NotFound]
        end

        it 'should upload blobs' do
          expect { subject.perform_async(artifact.id) }.to upload(
            { key: artifact.key_for('blobs/sha256/33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735') },
            { key: artifact.key_for('blobs/sha256/43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170') },
            { key: artifact.key_for('blobs/sha256/91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b') },
            { key: artifact.key_for('blobs/sha256/beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d') },
          )
        end
      end

      context 'when blobs are uploaded' do
        before do
          Aws.config[:s3][:stub_responses][:head_object] = []
        end

        it 'should not reupload blobs' do
          expect { subject.perform_async(artifact.id) }.to_not upload
        end
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :oci_image, :uploaded, account:) }

      it 'should not store manifest' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'UPLOADED'
      end

      it 'should not upload blobs' do
        expect { subject.perform_async(artifact.id) }.to_not upload
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :oci_image, :failed, account:) }

      it 'should not store manifest' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'FAILED'
      end

      it 'should not upload blobs' do
        expect { subject.perform_async(artifact.id) }.to_not upload
      end
    end
  end

  context 'when artifact is an invalid image' do
    let(:image_tarball) { file_fixture('invalid-1.2.3.tar').open }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: image_tarball }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :oci_image, :waiting, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :oci_image, :processing, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :oci_image, :uploaded, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :oci_image, :failed, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end
  end

  context 'when artifact is not an image' do
    let(:noise) { Random.bytes(1.megabyte) }

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: noise }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :waiting, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :processing, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :uploaded, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :failed, account:) }

      it 'should process image' do
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

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :processing, filesize: 1.gigabyte, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :uploaded, filesize: 1.gigabyte, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :failed, filesize: 1.gigabyte, account:) }

      it 'should process image' do
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

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'WAITING'
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :processing, content_length: 0, account:) }

      it 'should process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.manifest).to be nil
        expect(artifact.status).to eq 'FAILED'
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :uploaded, content_length: 0, account:) }

      it 'should not process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'UPLOADED'
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :failed, content_length: 0, account:) }

      it 'should not process image' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }

        expect(artifact.status).to eq 'FAILED'
      end
    end
  end

  context 'when artifact filesize is inaccurate' do
    let(:artifact) { create(:artifact, :processing, filesize: 1.kilobyte, account:) }
    let(:tgz)      { file_fixture('large.tar.gz').open }
    let(:tar)      { Zlib::GzipReader.new(tgz).read }

    before do
      Aws.config = {
        s3: {
          stub_responses: {
            head_object: [{ content_length: tar.size }],
            get_object: [{ body: tar }],
          },
        },
      }
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
