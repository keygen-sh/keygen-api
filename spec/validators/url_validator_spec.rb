# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe UrlValidator do
  let(:model) do
    Class.new do
      include ActiveModel::Model

      def self.name = 'UrlValidatorModel'

      attr_accessor :url

      validates :url, url: true
    end
  end

  subject { model.new(url:) }

  def stub_resolv!(host, *addrs)
    allow(Resolv).to receive(:getaddresses).with(host).and_return(addrs)
  end

  context 'with an invalid URL' do
    let(:url) { 'https://foo bar.example' }

    it { is_expected.to_not be_valid }
  end

  context 'with an invalid protocol' do
    let(:url) { 'ftp://ftp.example' }

    it { is_expected.to_not be_valid }
  end

  context 'with a protocols option' do
    let(:model) do
      Class.new do
        include ActiveModel::Model

        def self.name = 'UrlValidatorModel'

        attr_accessor :url

        validates :url, url: { protocols: %w[https] }
      end
    end

    context 'with a matching protocol' do
      let(:url) { 'https://webhooks.example' }

      it { is_expected.to be_valid }
    end

    context 'with a non-matching protocol' do
      let(:url) { 'http://webhooks.example' }

      it { is_expected.to_not be_valid }
    end
  end

  context 'with a blacklisted host' do
    %w[
      dist.keygen.sh
      app.keygen.sh
      api.keygen.sh
      dashboard.keygen.sh
      portal.keygen.sh
      status.keygen.sh
      stats.keygen.sh
      keygen.sh
      localhost
      foo.api.keygen.sh
      foo.bar.api.keygen.sh
      foo.keygen.sh
      foo.localhost
      API.KEYGEN.SH
      api.keygen.sh.
    ].each do |host|
      context "with host #{host}" do
        let(:url) { "https://#{host}" }

        it { is_expected.to_not be_valid }
      end
    end

    context 'with a look-alike host' do
      let(:url) { 'https://notkeygen.sh' }

      it { is_expected.to be_valid }
    end
  end

  context 'with a host without a TLD' do
    let(:url) { 'https://intranet' }

    it { is_expected.to_not be_valid }
  end

  context 'with an IP literal host' do
    context 'with an IPv4 literal' do
      let(:url) { 'https://10.0.0.1' }

      it { is_expected.to_not be_valid }
    end

    context 'with an IPv6 literal' do
      let(:url) { 'https://[::1]' }

      it { is_expected.to_not be_valid }
    end
  end

  context 'with a resolvable host' do
    let(:url) { 'https://webhooks.example' }

    def self.it_resolves_to(*addrs, valid:)
      context "when resolving to #{addrs.join(', ')}" do
        before { stub_resolv!('webhooks.example', *addrs) }

        if valid
          it { is_expected.to be_valid }
        else
          it { is_expected.to_not be_valid }

          it 'should add a host_private error' do
            subject.validate

            expect(subject.errors.details[:url]).to include(
              hash_including(error: :host_private),
            )
          end
        end
      end
    end

    # public addresses
    it_resolves_to '93.184.215.14', valid: true
    it_resolves_to '1.2.3.4', '5.6.7.8', valid: true
    it_resolves_to '2606:4700:4700::1111', valid: true
    it_resolves_to '64:ff9b::5db8:d70e', valid: true # NAT64-embedded 93.184.215.14

    # private/reserved IPv4
    it_resolves_to '0.0.0.0', valid: false
    it_resolves_to '10.0.0.1', valid: false
    it_resolves_to '100.64.0.1', valid: false # CGNAT
    it_resolves_to '127.0.0.1', valid: false
    it_resolves_to '169.254.169.254', valid: false # link-local/metadata
    it_resolves_to '172.16.0.1', valid: false
    it_resolves_to '192.0.0.1', valid: false
    it_resolves_to '192.0.2.1', valid: false # TEST-NET-1
    it_resolves_to '192.168.1.1', valid: false
    it_resolves_to '198.18.0.1', valid: false # benchmarking
    it_resolves_to '198.51.100.1', valid: false # TEST-NET-2
    it_resolves_to '203.0.113.1', valid: false # TEST-NET-3
    it_resolves_to '224.0.0.1', valid: false # multicast
    it_resolves_to '240.0.0.1', valid: false # reserved
    it_resolves_to '255.255.255.255', valid: false # broadcast

    # private/reserved IPv6
    it_resolves_to '::', valid: false
    it_resolves_to '::1', valid: false
    it_resolves_to '100::1', valid: false # discard-only
    it_resolves_to '2001::1', valid: false # Teredo
    it_resolves_to '2001:db8::1', valid: false # documentation
    it_resolves_to '2002::1', valid: false # 6to4
    it_resolves_to 'fc00::1', valid: false # ULA
    it_resolves_to 'fe80::1', valid: false # link-local
    it_resolves_to 'ff02::1', valid: false # multicast

    # IPv4-mapped IPv6 (rejected outright, even for public addresses)
    it_resolves_to '::ffff:10.0.0.1', valid: false
    it_resolves_to '::ffff:127.0.0.1', valid: false
    it_resolves_to '::ffff:169.254.169.254', valid: false
    it_resolves_to '::ffff:224.0.0.1', valid: false
    it_resolves_to '::ffff:93.184.215.14', valid: false

    # IPv4-compatible IPv6 (rejected outright, even for public addresses)
    it_resolves_to '::10.0.0.1', valid: false
    it_resolves_to '::93.184.215.14', valid: false

    # NAT64-embedded IPv4 bypasses
    it_resolves_to '64:ff9b::a00:1', valid: false # 10.0.0.1
    it_resolves_to '64:ff9b::7f00:1', valid: false # 127.0.0.1
    it_resolves_to '64:ff9b:1::a9fe:a9fe', valid: false # 169.254.169.254

    # mixed answers fail closed
    it_resolves_to '93.184.215.14', '10.0.0.1', valid: false
    it_resolves_to '2606:4700:4700::1111', '::1', valid: false
  end

  context 'with an unresolvable host' do
    let(:url) { 'https://webhooks.example' }

    before { stub_resolv!('webhooks.example') }

    it { is_expected.to_not be_valid }
  end

  context 'with an unparseable resolved address' do
    let(:url) { 'https://webhooks.example' }

    before { stub_resolv!('webhooks.example', 'garbage') }

    it { is_expected.to_not be_valid }
  end
end
