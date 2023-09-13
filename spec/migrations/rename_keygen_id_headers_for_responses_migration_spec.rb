# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameKeygenIdHeadersForResponsesMigration do
  Response = Data.define(:headers)

  let(:migration) { RenameKeygenIdHeadersForResponsesMigration.new }

  it 'should migrate response headers when present' do
    account_id = SecureRandom.uuid
    bearer_id  = SecureRandom.uuid
    token_id   = SecureRandom.uuid
    response   = Response.new(headers: {
      'Keygen-Account' => account_id,
      'Keygen-Bearer' => bearer_id,
      'Keygen-Token' => token_id,
    })

    migration.migrate_response!(response)

    expect(response.headers).to eq(
      'Keygen-Account-Id' => account_id,
      'Keygen-Bearer-Id' => bearer_id,
      'Keygen-Token-Id' => token_id,
    )
  end

  it 'should not migrate response headers when missing' do
    account_id = SecureRandom.uuid
    bearer_id  = SecureRandom.uuid
    token_id   = SecureRandom.uuid
    response   = Response.new(headers: {
      'Keygen-Account' => account_id,
      'Keygen-Version' => '1.0',
    })

    migration.migrate_response!(response)

    expect(response.headers).to eq(
      'Keygen-Account-Id' => account_id,
      'Keygen-Version' => '1.0',
    )
  end
end
