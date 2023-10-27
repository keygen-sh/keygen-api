# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe UpdateNestedKeyCasingToSnakecaseForMetadataMigration do
  let(:account) { create(:account) }

  before do
    RequestMigrations.configure do |config|
      config.current_version = CURRENT_API_VERSION
      config.versions        = {
        '1.0' => [UpdateNestedKeyCasingToSnakecaseForMetadataMigration],
      }
    end
  end

  it 'should migrate metadata for records' do
    migrator = RequestMigrations::Migrator.new(from: CURRENT_API_VERSION, to: '1.0')
    data     = Keygen::JSONAPI.render(
      [
        create(:license, account:, metadata: { parent_key: { child_key: { grand_child_key: 'value' } } }),
        create(:license, account:, metadata: { parent_key: { child_key: 'value' } }),
        create(:license, account:, metadata: { a_key: [{ item_key: 'value' }] }),
        create(:license, account:, metadata: { a_key: ['value'] }),
        create(:license, account:, metadata: { a_key: 'value' }),
      ],
      api_version: CURRENT_API_VERSION,
      account:,
    )

    expect(data).to include(
      data: [
        include(
          attributes: include(
            metadata: {
              'parentKey' => { 'childKey' => { 'grandChildKey' => 'value' } },
            },
          ),
        ),
        include(
          attributes: include(
            metadata: {
              'parentKey' => { 'childKey' => 'value' },
            },
          ),
        ),
        include(
          attributes: include(
            metadata: {
              'aKey' => [{ 'itemKey' => 'value' }],
            },
          ),
        ),
        include(
          attributes: include(
            metadata: {
              'aKey' => ['value'],
            },
          ),
        ),
        include(
          attributes: include(
            metadata: {
              'aKey' => 'value',
            },
          ),
        ),
      ],
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: [
        include(
          attributes: include(
            metadata: {
              'parentKey' => { 'child_key' => { 'grand_child_key' => 'value' } },
            },
          ),
        ),
        include(
          attributes: include(
            metadata: {
              'parentKey' => { 'child_key' => 'value' },
            },
          ),
        ),
        include(
          attributes: include(
            metadata: {
              'aKey' => [{ 'item_key' => 'value' }],
            },
          ),
        ),
        include(
          attributes: include(
            metadata: {
              'aKey' => ['value'],
            },
          ),
        ),
        include(
          attributes: include(
            metadata: {
              'aKey' => 'value',
            },
          ),
        ),
      ],
    )
  end

  it 'should migrate metadata for record' do
    migrator = RequestMigrations::Migrator.new(from: CURRENT_API_VERSION, to: '1.0')
    data     = Keygen::JSONAPI.render(
      create(:license, account:, metadata: { parent_key: { child_key: { grand_child_key: 'value' } } }),
      api_version: CURRENT_API_VERSION,
      account:,
    )

    expect(data).to include(
      data: include(
        attributes: include(
          metadata: {
            'parentKey' => { 'childKey' => { 'grandChildKey' => 'value' } },
          },
        ),
      ),
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: include(
        attributes: include(
          metadata: {
            'parentKey' => { 'child_key' => { 'grand_child_key' => 'value' } },
          },
        ),
      ),
    )
  end
end
