# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe :deep_include do
  let(:array) { [hash] }
  let(:hash) {
    {
      data: {
        foo: {
          bar: 1,
          baz: 2,
        },
        qux: {
          quxx: 3,
          corge: 4,
        },
        grault: {
          garply: 5,
          waldo: 6,
        },
        fred: {
          plugh: 7,
          xyzzy: 8,
        },
        thud: 9,
      },
    }
  }

  it 'should match a hash' do
    expect(hash).to deep_include(
      data: { foo: { bar: 1 } },
    )
  end

  it 'should not match a hash' do
    expect(hash).to_not deep_include(
      data: { foo: { quxx: Integer } },
    )
  end

  it 'should match an array' do
    expect(array).to deep_include(
      data: { qux: { quxx: Integer } },
    )
  end

  it 'should not match an array' do
    expect(array).to_not deep_include(
      data: { baz: { quxx: 2 } },
    )
  end
end
