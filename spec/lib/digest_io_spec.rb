# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'digest_io'

RSpec.describe DigestIO do
  let(:digest) { Digest::SHA256.new }

  describe '#write' do
    it 'calculates the correct digest' do
      io = DigestIO.new(StringIO.new, digest:)
      io.write('foo')
      io.write(' ')
      io.write('bar')

      expect(io.hexdigest).to eq(
        Digest::SHA256.hexdigest('foo bar'),
      )
    end
  end
end
