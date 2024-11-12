# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe TokenLookupService do
  context 'when token is a v1 token' do
    let(:token)     { '1780aeccbbb14b4dad0cf8b8165faba2.52f61713fd0c49a2a6537e3142d043cb.3e2373c60b7df8514ff763dad707faad44956c2421fdb2588fff2a73099b07v1' }
    let(:account_id) { token.split('.').first }
    let(:token_id)   { token.split('.').second }
    let(:account)    { create(:account, id: account_id) }
    let(:product)    { create(:product, account:) }

    context 'when token is a good token' do
      let(:digest) { '$2a$12$7sgr9E9ZURyXzttcuIl/muYRww.wHxNgCpgUHsKODV2ZXpPWiqLkq' }

      subject! {
        record = create(:token, id: token_id, bearer: product, account:)
        record.update!(digest:)
        record
      }

      it 'should pass lookup' do
        record = described_class.call(token:, account:)

        expect(record).to eq subject
      end

      it 'should not rehash' do
        expect { described_class.call(token:, account:) }.to_not(
          change { subject.reload.digest },
        )
      end
    end

    context 'when token is a bad token' do
      let(:digest) { '$2a$12$7sgr9E9ZURyXzttcuIl/muSl7JViEcBcytnbouQooX22PP43AzZ4C' }

      subject! {
        record = create(:token, id: token_id, bearer: product, account:)
        record.update!(digest:)
        record
      }

      it 'should pass lookup' do
        record = described_class.call(token:, account:)

        expect(record).to eq subject
      end

      it 'should rehash' do
        expect { described_class.call(token:, account:) }.to(
          change { subject.reload.digest },
        )

        # sanity check
        ok = subject.compare_hashed_token(:digest, token, version: 'v1')
        expect(ok).to be true
      end
    end
  end

  context 'when token is a v2 token' do
    let(:token)   { 'prod-c5cf2bc0986bb90cae46dade120172c1451abfc3429a4f9057a9786738d192v2' }
    let(:digest)  { '0c8f765a79a45992c1031f8cc69b858a960257ee16bfd67e26487913565e04337c25897b62011d45b75a7bc20a7e16057fef2573d32f91c1f264f595cfdd2a04' }
    let(:account) { create(:account) }
    let(:product) { create(:product, account:) }

    subject! {
      record = create(:token, bearer: product, account:)
      record.update!(digest:)
      record
    }

    it 'should pass lookup' do
      record = described_class.call(token:, account:)

      expect(record).to eq subject
    end

    it 'should not rehash' do
      expect { described_class.call(token:, account:) }.to_not(
        change { subject.reload.digest },
      )
    end
  end

  context 'when token is a v3 token' do
    let(:secret_key) { '9ef57edb7f2a91bed90805744cdbf4ece13905ad2670bc1f54212074043cede710ca6a60c95114cf16fbbef7d696b0c61649250a9baf14aab878e5f85f769836' }
    let(:token)      { 'prod-580839d4388a61216398c83f2c987a80dee472f556db7bc9aa66775574de54f4v3' }
    let(:digest)     { '0e555b39a256a319674356f834d39de70c06b0d0ef94f4b8f9c7d34bdc287f93' }
    let(:product)    { create(:product, account:) }
    let(:account)    {
      record = create(:account)
      record.update(secret_key:)
      record
    }

    subject! {
      record = create(:token, bearer: product, account:)
      record.update!(digest:)
      record
    }

    it 'should pass lookup' do
      record = described_class.call(token:, account:)

      expect(record).to eq subject
    end

    it 'should not rehash' do
      expect { described_class.call(token:, account:) }.to_not(
        change { subject.reload.digest },
      )
    end
  end

  context 'when token is invalid' do
    let(:token)   { 'user-f25149752c704e0c8281150c6751ba77052111ad14214d5adacd0a80d45cc957v3' }
    let(:account) { create(:account) }

    it 'should fail lookup' do
      record = described_class.call(token:, account:)

      expect(record).to be nil
    end
  end
end
