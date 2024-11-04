# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe :allocate_less_than do
  let!(:stream) { StringIO.new(SecureRandom.bytes(50.megabytes)) }

  it 'should pass when allocations are under limit' do
    expect { stream.read(1.megabyte - 1.kilobyte) }.to allocate_less_than(1.megabyte)
  end

  it 'should fail when allocations are over limit' do
    expect { stream.read(1.megabyte + 1.kilobyte) }.to allocate_at_least(1.megabyte)
  end

  it 'should pass when chunk size is under the limit' do
    expect {
      while chunk = stream.read(512.kilobytes)
        chunk
      end
    }.to allocate_less_than(5.megabytes)
  end

  it 'should fail when chunk accum exceeds the limit' do
    expect {
      chunks = +'' # retain all chunks

      while chunk = stream.read(512.kilobytes)
        chunks << chunk
      end

      chunks
    }.to allocate_at_least(50.megabytes)
  end

  it 'should fail when chunk size exceeds the limit' do
    expect {
      while chunk = stream.read(25.megabytes)
        chunk
      end
    }.to allocate_at_least(25.megabytes)
  end
end
