# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Hostname do
  subject { described_class.new('webhooks.example') }

  def stub_resolv!(*addrs)
    allow(Hostname::DNS_RESOLVER).to receive(:getaddresses).with('webhooks.example').and_return(addrs)
  end

  describe '#ipaddrs' do
    it 'should return the addresses the hostname resolves to' do
      stub_resolv! '93.184.215.14', '2606:2800:21f:cb07:6820:80da:af6b:8b2c'

      expect(subject.ipaddrs).to eq %w[93.184.215.14 2606:2800:21f:cb07:6820:80da:af6b:8b2c]
    end

    it 'should be empty when the hostname does not resolve' do
      stub_resolv!

      expect(subject.ipaddrs).to be_empty
    end

    it 'should be empty when the hostname resolves to an unacceptable address' do
      stub_resolv! '127.0.0.1'

      expect(subject.ipaddrs).to be_empty
    end

    it 'should be empty when the hostname resolves to any unacceptable address' do
      stub_resolv! '93.184.215.14', '10.0.0.1'

      expect(subject.ipaddrs).to be_empty
    end

    it 'should be empty when resolution fails' do
      allow(Hostname::DNS_RESOLVER).to receive(:getaddresses).and_raise(Resolv::ResolvTimeout)

      expect(subject.ipaddrs).to be_empty
    end

    it 'should resolve on every call' do
      stub_resolv! '93.184.215.14'

      2.times { subject.ipaddrs }

      expect(Hostname::DNS_RESOLVER).to have_received(:getaddresses).twice
    end

    it 'should allow explicitly permitted private addresses' do
      stub_resolv! '10.0.0.1'

      with_env KEYGEN_ALLOWED_PRIVATE_ADDRESSES: '10.0.0.0/8' do
        expect(subject.ipaddrs).to eq %w[10.0.0.1]
      end
    end
  end
end
