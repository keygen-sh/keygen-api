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

    before do
      Aws.config = { s3: { stub_responses: { get_object: [{ body: image_tarball }] } } }
    end

    context 'when artifact is waiting' do
      let(:artifact) { create(:artifact, :oci_image, :waiting, account:) }

      it 'should not change artifact status' do
        expect { subject.perform_async(artifact.id) }.to_not change { artifact.reload.status }
      end

      it 'should not store manifest' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end

      it 'should not upload blobs' do
        expect { subject.perform_async(artifact.id) }.to_not upload
      end
    end

    context 'when artifact is processing' do
      let(:artifact) { create(:artifact, :oci_image, :processing, account:) }

      it 'should change artifact status' do
        expect { subject.perform_async(artifact.id) }.to change { artifact.reload.status }.to('UPLOADED')
      end

      it 'should store manifests' do
        expect { subject.perform_async(artifact.id) }.to change { artifact.reload.manifests }

        expect(artifact.manifests).to satisfy { |manifests|
          manifests in [
            ReleaseManifest(content_path: 'blobs/sha256/beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d', content_digest: 'sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d', content_type: 'application/vnd.docker.distribution.manifest.list.v2+json', content_length: 1853, content: String),
            ReleaseManifest(content_path: 'blobs/sha256/33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735', content_digest: 'sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735', content_type: 'application/vnd.docker.distribution.manifest.v2+json',      content_length: 528,  content: String),
          ]
        }
      end

      context 'when blobs are not uploaded' do
        before do
          Aws.config[:s3][:stub_responses][:head_object] = [Aws::S3::Errors::NotFound]
        end

        it 'should store blobs' do
          expect { subject.perform_async(artifact.id) }.to change { artifact.reload.descriptors }

          expect(artifact.descriptors).to satisfy { |descriptors|
            descriptors in [
              ReleaseDescriptor(content_path: 'oci-layout',                                                                    content_type: 'application/vnd.oci.layout.header.v1+json',                 content_digest: 'sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6', content_length: 30),
              ReleaseDescriptor(content_path: 'index.json',                                                                    content_type: 'application/vnd.oci.image.index.v1+json',                   content_digest: 'sha256:355eee6af939abf5ba465c9be69c3b725f8d3f19516ca9644cf2a4fb112fd83b', content_length: 441),
              ReleaseDescriptor(content_path: 'blobs/sha256/beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d', content_type: 'application/vnd.docker.distribution.manifest.list.v2+json', content_digest: 'sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d', content_length: 1853),
              ReleaseDescriptor(content_path: 'blobs/sha256/33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735', content_type: 'application/vnd.docker.distribution.manifest.v2+json',      content_digest: 'sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735', content_length: 528),
              ReleaseDescriptor(content_path: 'blobs/sha256/43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170', content_type: 'application/vnd.docker.image.rootfs.diff.tar.gzip',         content_digest: 'sha256:43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170', content_length: 3623807),
              ReleaseDescriptor(content_path: 'blobs/sha256/91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b', content_type: 'application/vnd.docker.container.image.v1+json',            content_digest: 'sha256:91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b', content_length: 1471),
            ]
          }
        end

        it 'should upload blobs' do
          expect { subject.perform_async(artifact.id) }.to upload(
            { key: %r{oci-layout},                                                                    content_type: 'application/vnd.oci.layout.header.v1+json',                 content_length: 30 },
            { key: %r{index.json},                                                                    content_type: 'application/vnd.oci.image.index.v1+json',                   content_length: 441 },
            { key: %r{blobs/sha256/beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d}, content_type: 'application/vnd.docker.distribution.manifest.list.v2+json', content_length: 1853 },
            { key: %r{blobs/sha256/33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735}, content_type: 'application/vnd.docker.distribution.manifest.v2+json',      content_length: 528 },
            { key: %r{blobs/sha256/43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170}, content_type: 'application/vnd.docker.image.rootfs.diff.tar.gzip',         content_length: 3623807 },
            { key: %r{blobs/sha256/91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b}, content_type: 'application/vnd.docker.container.image.v1+json',            content_length: 1471 },
          )
        end
      end

      context 'when blobs are uploaded' do
        before do
          Aws.config[:s3][:stub_responses][:head_object] = []
        end

        it 'should store blobs' do
          expect { subject.perform_async(artifact.id) }.to change { artifact.reload.descriptors }

          expect(artifact.descriptors).to satisfy { |descriptors|
            descriptors in [
              ReleaseDescriptor(content_path: 'oci-layout',                                                                    content_type: 'application/vnd.oci.layout.header.v1+json',                 content_digest: 'sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6', content_length: 30),
              ReleaseDescriptor(content_path: 'index.json',                                                                    content_type: 'application/vnd.oci.image.index.v1+json',                   content_digest: 'sha256:355eee6af939abf5ba465c9be69c3b725f8d3f19516ca9644cf2a4fb112fd83b', content_length: 441),
              ReleaseDescriptor(content_path: 'blobs/sha256/beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d', content_type: 'application/vnd.docker.distribution.manifest.list.v2+json', content_digest: 'sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d', content_length: 1853),
              ReleaseDescriptor(content_path: 'blobs/sha256/33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735', content_type: 'application/vnd.docker.distribution.manifest.v2+json',      content_digest: 'sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735', content_length: 528),
              ReleaseDescriptor(content_path: 'blobs/sha256/43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170', content_type: 'application/vnd.docker.image.rootfs.diff.tar.gzip',         content_digest: 'sha256:43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170', content_length: 3623807),
              ReleaseDescriptor(content_path: 'blobs/sha256/91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b', content_type: 'application/vnd.docker.container.image.v1+json',            content_digest: 'sha256:91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b', content_length: 1471),
            ]
          }
        end

        it 'should not reupload blobs' do
          expect { subject.perform_async(artifact.id) }.to_not upload
        end
      end
    end

    context 'when artifact is uploaded' do
      let(:artifact) { create(:artifact, :oci_image, :uploaded, account:) }

      it 'should not change artifact status' do
        expect { subject.perform_async(artifact.id) }.to_not change { artifact.reload.status }
      end

      it 'should not store manifest' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
      end

      it 'should not upload blobs' do
        expect { subject.perform_async(artifact.id) }.to_not upload
      end
    end

    context 'when artifact is failed' do
      let(:artifact) { create(:artifact, :oci_image, :failed, account:) }

      it 'should not change artifact status' do
        expect { subject.perform_async(artifact.id) }.to_not change { artifact.reload.status }
      end

      it 'should not store manifest' do
        expect { subject.perform_async(artifact.id) }.to not_change { artifact.reload.manifest }
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
