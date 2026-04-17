# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'hash_filter'

RSpec.describe HashFilter do
  describe '#initialize' do
    it 'raises when the mask is not callable' do
      expect { HashFilter.new(%i[token], mask: '[REDACTED]') }
        .to raise_error(ArgumentError, /mask must be callable/)
    end

    it 'accepts a callable mask' do
      expect { HashFilter.new(%i[token], mask: ->(v) { v }) }
        .not_to raise_error
    end
  end

  describe '#filter' do
    context 'with a matching key' do
      it 'reveals the first and last EDGE_SIZE chars for strings longer than MIN_SIZE' do
        value    = 'a' * (HashFilter::MIN_SIZE + 1)
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: value)

        expect(filtered).to eq(token: "#{value[0, 4]}...#{value[-4, 4]}")
      end

      it 'reveals only the first and last char for strings at or below MIN_SIZE' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: 'abcdefghij')

        expect(filtered).to eq(token: 'a...j')
      end

      it 'reveals only the first and last char at exactly MIN_SIZE' do
        value    = 'a' * HashFilter::MIN_SIZE
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: value)

        expect(filtered).to eq(token: 'a...a')
      end

      it 'reveals the first and last EDGE_SIZE chars just above MIN_SIZE' do
        value    = ('a'..'z').first(HashFilter::MIN_SIZE + 1).join
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: value)

        expect(filtered).to eq(token: "#{value[0, 4]}...#{value[-4, 4]}")
      end

      it 'masks an empty string to just the ellipsis' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: '')

        expect(filtered).to eq(token: '...')
      end

      it 'masks symbol values by coercing to a string' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: :abcdefghijklmnopqrstuvwxyz)

        expect(filtered).to eq(token: 'abcd...wxyz')
      end

      it 'masks integer values by coercing to a string' do
        filterer = HashFilter.new(%i[otp])
        filtered = filterer.filter(otp: 123456)

        expect(filtered).to eq(otp: '1...6')
      end

      it 'masks BigDecimal values by coercing to a string' do
        filterer = HashFilter.new(%i[secret])
        filtered = filterer.filter(secret: BigDecimal('1234567890.1234'))

        expect(filtered).to match(secret: /\A1.*4\z/)
        expect(filtered[:secret]).not_to include('1234567890.1234')
      end

      it 'masks each element of an array value independently' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: %w[oldtokenvalue newtokenvalue])

        expect(filtered).to eq(token: %w[o...e n...e])
      end

      it 'masks each value of a hash value independently' do
        filterer = HashFilter.new(%i[secret])
        filtered = filterer.filter(secret: { pin: 9823, code: 'abcdefghij' })

        expect(filtered).to eq(secret: { pin: '9...3', code: 'a...j' })
      end

      it 'masks every scalar in a mixed nested structure' do
        filterer = HashFilter.new(%i[secret])
        filtered = filterer.filter(secret: { inner: [12, 'abcdefghijklmnopqrstuvwxyz'], also: [1, 'abcdefghijklmnopqrstuvwxyz'] })

        expect(filtered).to eq(
          secret: {
            inner: ['1...2', 'abcd...wxyz'],
            also: ['...', 'abcd...wxyz'],
          },
        )
      end

      it 'passes through nil as non-sensitive' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: nil)

        expect(filtered).to eq(token: nil)
      end

      it 'passes through true as non-sensitive' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: true)

        expect(filtered).to eq(token: true)
      end

      it 'passes through false as non-sensitive' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: false)

        expect(filtered).to eq(token: false)
      end

      it 'passes through nil and bools nested inside an array value' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(token: [nil, true, false, 'abcdefghij'])

        expect(filtered).to eq(token: [nil, true, false, 'a...j'])
      end

      it 'passes through nil and bools nested inside a hash value' do
        filterer = HashFilter.new(%i[secret])
        filtered = filterer.filter(secret: { a: nil, b: true, c: false, d: 'abcdefghij' })

        expect(filtered).to eq(secret: { a: nil, b: true, c: false, d: 'a...j' })
      end
    end

    context 'with a non-matching key' do
      it 'leaves string values untouched' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(email: 'user@example.com')

        expect(filtered).to eq(email: 'user@example.com')
      end

      it 'leaves non-string values untouched' do
        filterer = HashFilter.new(%i[token])
        filtered = filterer.filter(count: 42, active: true, missing: nil)

        expect(filtered).to eq(count: 42, active: true, missing: nil)
      end
    end

    context 'with a dotted filter key' do
      it 'matches against the full nested path' do
        filterer = HashFilter.new(['user.token'])
        filtered = filterer.filter(user: { token: 'abcdefghijklmnopqrstuvwxyz' }, post: { token: 'foo' })

        expect(filtered).to eq(
          user: { token: 'abcd...wxyz' },
          post: { token: 'foo' },
        )
      end
    end

    context 'with a custom callable mask' do
      it 'invokes the mask with the original value' do
        mask     = ->(value) { "<#{value.to_s.length}>" }
        filterer = HashFilter.new(%i[token], mask:)
        filtered = filterer.filter(token: 'abcdefghij')

        expect(filtered).to eq(token: '<10>')
      end
    end
  end
end
