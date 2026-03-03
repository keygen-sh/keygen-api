# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RecordReleaseDownloadSparkWorker, :only_clickhouse do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  it 'should aggregate per-product, per-package, and per-release' do
    product_a    = create(:product, account:)
    product_a_id = product_a.id

    product_b    = create(:product, account:)
    product_b_id = product_b.id

    package_a    = create(:release_package, account:, product: product_a)
    package_a_id = package_a.id

    release_a    = create(:release, account:, product: product_a, package: package_a)
    release_a_id = release_a.id

    release_b    = create(:release, account:, product: product_a, package: package_a)
    release_b_id = release_b.id

    release_c    = create(:release, account:, product: product_b)
    release_c_id = release_c.id

    artifact_a = create(:release_artifact, account:, release: release_a)
    artifact_b = create(:release_artifact, account:, release: release_b)
    artifact_c = create(:release_artifact, account:, release: release_c)

    create_list(:event_log, 3, :artifact_downloaded, account:, resource: artifact_a, metadata: { product: product_a_id, package: package_a_id, release: release_a_id, version: release_a.version })
    create_list(:event_log, 2, :artifact_downloaded, account:, resource: artifact_b, metadata: { product: product_a_id, package: package_a_id, release: release_b_id, version: release_b.version })
    create_list(:event_log, 1, :artifact_downloaded, account:, resource: artifact_c, metadata: { product: product_b_id, package: nil,          release: release_c_id, version: release_c.version })

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = ReleaseDownloadSpark.for_account(account)
                                 .order(
                                   created_at: :desc,
                                 )

    expect(sparks).to satisfy do
      it in [
        ReleaseDownloadSpark(product_id: ^product_b_id, package_id: nil,           release_id: ^release_c_id, count: 1),
        ReleaseDownloadSpark(product_id: ^product_a_id, package_id: ^package_a_id, release_id: ^release_b_id, count: 2),
        ReleaseDownloadSpark(product_id: ^product_a_id, package_id: ^package_a_id, release_id: ^release_a_id, count: 3),
      ]
    end
  end

  it 'should aggregate per-environment' do
    environment_a    = create(:environment, :shared, account:)
    environment_a_id = environment_a.id

    environment_b    = create(:environment, account:)
    environment_b_id = environment_b.id

    product_a    = create(:product, account:, environment: environment_a)
    product_a_id = product_a.id

    product_b    = create(:product, account:, environment: environment_b)
    product_b_id = product_b.id

    product_c    = create(:product, account:, environment: nil)
    product_c_id = product_c.id

    release_a    = create(:release, account:, product: product_a, environment: environment_a)
    release_a_id = release_a.id

    release_b    = create(:release, account:, product: product_b, environment: environment_b)
    release_b_id = release_b.id

    release_c    = create(:release, account:, product: product_c, environment: nil)
    release_c_id = release_c.id

    artifact_a = create(:release_artifact, account:, release: release_a, environment: environment_a)
    artifact_b = create(:release_artifact, account:, release: release_b, environment: environment_b)
    artifact_c = create(:release_artifact, account:, release: release_c, environment: nil)

    create_list(:event_log, 3, :artifact_downloaded, account:, resource: artifact_a, environment: environment_a, metadata: { product: product_a_id, package: nil, release: release_a_id, version: release_a.version })
    create_list(:event_log, 2, :artifact_downloaded, account:, resource: artifact_b, environment: environment_b, metadata: { product: product_b_id, package: nil, release: release_b_id, version: release_b.version })
    create_list(:event_log, 1, :artifact_downloaded, account:, resource: artifact_c, environment: nil,           metadata: { product: product_c_id, package: nil, release: release_c_id, version: release_c.version })

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = ReleaseDownloadSpark.for_account(account)
                                 .order(
                                   created_at: :desc,
                                 )

    expect(sparks).to satisfy do
      it in [
        ReleaseDownloadSpark(environment_id: nil,               release_id: ^release_c_id, count: 1),
        ReleaseDownloadSpark(environment_id: ^environment_b_id, release_id: ^release_b_id, count: 2),
        ReleaseDownloadSpark(environment_id: ^environment_a_id, release_id: ^release_a_id, count: 3),
      ]
    end
  end

  it 'should not record sparks when there are no download events' do
    create(:release, account:)

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = ReleaseDownloadSpark.for_account(account)

    expect(sparks.count).to eq(0)
  end

  it 'should not record sparks for non-download events' do
    license = create(:license, account:)

    create_list(:event_log, 3, :license_created, account:, resource: license)

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = ReleaseDownloadSpark.for_account(account)

    expect(sparks.count).to eq(0)
  end

  it 'should not record sparks for other accounts' do
    other_account  = create(:account)
    other_product  = create(:product, account: other_account)
    other_release  = create(:release, account: other_account, product: other_product)
    other_artifact = create(:release_artifact, account: other_account, release: other_release)

    product  = create(:product, account:)
    release  = create(:release, account:, product:)
    artifact = create(:release_artifact, account:, release:)

    create_list(:event_log, 3, :artifact_downloaded, account: other_account, resource: other_artifact, metadata: { product: other_product.id, package: nil, release: other_release.id, version: other_release.version })
    create_list(:event_log, 3, :artifact_downloaded, account:,               resource: artifact,       metadata: { product: product.id,       package: nil, release: release.id,       version: release.version })

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    other_sparks = ReleaseDownloadSpark.for_account(other_account)

    expect(other_sparks.count).to eq(0)

    sparks = ReleaseDownloadSpark.for_account(account)

    expect(sparks.count).to eq(1)
  end
end
