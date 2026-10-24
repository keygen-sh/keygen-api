# frozen_string_literal: true

shared_examples 'a duration-aware checkout' do |resource|
  let(:policy) { create(:policy, account:, duration_strategy: 'SECONDS') }
  let(:license) { create(:license, account:, policy:) }
  let(:ttl) { 90 * 86_400 }
  let(:checkout_options) { { ttl: } }
  let(:file) { described_class.call(account:, **{ resource => public_send(resource) }, **checkout_options) }

  around { |example| travel_to(Time.utc(2026, 10, 9)) { example.run } }

  it 'should issue a signed certificate whose TTL is exact seconds' do
    doc  = JSON.parse(Base64.decode64(file.certificate.lines[1...-1].join))
    data = JSON.parse(Base64.strict_decode64(doc.fetch('enc')))
    key  = Ed25519::VerifyKey.new([account.ed25519_public_key].pack('H*'))

    expect(file.expires_at).to eq Time.utc(2027, 1, 7)
    expect(file.expires_at - file.issued_at).to eq ttl
    expect(data.fetch('meta')).to include(
      'issued' => file.issued_at.iso8601(3),
      'expiry' => file.expires_at.iso8601(3),
      'ttl' => ttl,
    )
    expect { key.verify(Base64.strict_decode64(doc.fetch('sig')), "#{resource}/#{doc.fetch('enc')}") }.to_not raise_error
    expect { file.validate! }.to_not raise_error
  end

  context 'with a calendar policy' do
    before { policy.update!(duration_strategy: 'CALENDAR') }

    it 'should preserve the calendar expiry' do
      expect(file.expires_at).to eq Time.utc(2027, 1, 7, 3, 1, 48)
    end
  end

  context 'with a legacy policy' do
    before { policy.update_column(:duration_strategy, nil) }

    it 'should preserve the calendar expiry without opting in' do
      expect(file.expires_at).to eq Time.utc(2027, 1, 7, 3, 1, 48)
    end
  end

  context 'with the default TTL' do
    let(:checkout_options) { {} }

    it 'should use the default month value as exact seconds when opted in' do
      expect(file.expires_at - file.issued_at).to eq 2_629_746
    end
  end

  context 'with a Rails duration TTL' do
    let(:ttl) { 3.months }

    it 'should use the numeric duration value as exact seconds when opted in' do
      expect(file.expires_at - file.issued_at).to eq 7_889_238
    end
  end

  context 'without a TTL' do
    let(:ttl) { nil }

    it 'should preserve non-expiring certificates' do
      expect(file.expires_at).to be_nil
      expect(file.ttl).to be_nil
    end
  end

  context 'with the minimum TTL' do
    let(:ttl) { 3_600 }

    it 'should accept a one-hour certificate' do
      expect(file.expires_at - file.issued_at).to eq ttl
    end
  end

  context 'with a TTL below the minimum' do
    let(:ttl) { 3_599 }

    it 'should preserve the TTL validation' do
      expect { file }.to raise_error AbstractCheckoutService::InvalidTTLError
    end
  end

  it 'should preserve already issued certificates after a policy change' do
    policy.update!(duration_strategy: 'CALENDAR')
    certificate = file.certificate
    expiry      = file.expires_at

    policy.update!(duration_strategy: 'SECONDS')
    checked_out = described_class.call(account:, **{ resource => public_send(resource).reload }, **checkout_options)
    doc         = JSON.parse(Base64.decode64(certificate.lines[1...-1].join))
    data        = JSON.parse(Base64.strict_decode64(doc.fetch('enc')))

    expect(file.certificate).to eq certificate
    expect(file.expires_at).to eq expiry
    expect(data.fetch('meta').fetch('expiry')).to eq '2027-01-07T03:01:48.000Z'
    expect(checked_out.expires_at).to eq Time.utc(2027, 1, 7)
  end
end
