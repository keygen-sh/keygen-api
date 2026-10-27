# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'keygen'

describe Keygen::Portal do
  describe '.url_for' do
    it 'should return the origin without a path' do
      url = Keygen::Portal.url_for

      expect(url).to eq Keygen::Portal::ORIGIN
    end

    it 'should return a url for a string path' do
      url = Keygen::Portal.url_for('/sso/error')

      expect(url).to eq "#{Keygen::Portal::ORIGIN}/sso/error"
    end

    it 'should return a url for a symbol path' do
      url = Keygen::Portal.url_for(:billing)

      expect(url).to eq "#{Keygen::Portal::ORIGIN}/billing"
    end

    it 'should return a url for an account' do
      account = build(:account)
      url     = Keygen::Portal.url_for(account)

      expect(url).to eq "#{Keygen::Portal::ORIGIN}/#{account.slug}"
    end

    it 'should return a url with query params' do
      url = Keygen::Portal.url_for('/sso/error', query: { code: 'SSO_ERROR', env: nil })

      expect(url).to eq "#{Keygen::Portal::ORIGIN}/sso/error?code=SSO_ERROR"
    end

    it 'should return a url with a host override' do
      url = Keygen::Portal.url_for('/sso/error', host: 'beta.portal.keygen.sh')

      expect(url).to eq 'https://beta.portal.keygen.sh/sso/error'
    end

    it 'should return a url for an account with a host override' do
      account = build(:account)
      url     = Keygen::Portal.url_for(account, host: 'beta.portal.keygen.sh')

      expect(url).to eq "https://beta.portal.keygen.sh/#{account.slug}"
    end

    it 'should return a url with a host override and query params' do
      url = Keygen::Portal.url_for('/acme/auth/reset', host: 'beta.portal.keygen.sh', query: { token: 'secret', env: 'production' })

      expect(url).to eq 'https://beta.portal.keygen.sh/acme/auth/reset?env=production&token=secret'
    end
  end
end
