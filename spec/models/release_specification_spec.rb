# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ReleaseManifest, type: :model do
  let(:account)  { create(:account) }
  let(:artifact) { create(:artifact, account:) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching artifact' do
        environment = create(:environment, account:)
        artifact    = create(:artifact, account:, environment:)
        manifest    = create(:manifest, artifact:, account:)

        expect(manifest.environment).to eq artifact.environment
      end

      it 'should not raise when environment matches artifact' do
        environment = create(:environment, account:)
        artifact    = create(:artifact, account:, environment:)

        expect { create(:manifest, artifact:, account:, environment:) }.to_not raise_error
      end

      it 'should raise when environment does not match artifact' do
        artifact = create(:artifact, account:, environment: nil)

        expect { create(:manifest, environment: create(:environment, account:), artifact:, account:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches artifact' do
        environment = create(:environment, account:)
        manifest    = create(:manifest, account:, environment:)

        expect { manifest.update!(artifact: create(:artifact, release: manifest.release, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match artifact' do
        environment = create(:environment, account:)
        manifest    = create(:manifest, account:, environment:)

        expect { manifest.update!(artifact: create(:artifact, release: manifest.release, environment: nil, account:)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
