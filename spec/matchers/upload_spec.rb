# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe :upload do
  let(:client) { Aws::S3::Client.new(stub_responses: true) }
  let(:noise)  { Random.bytes(1.kilobyte) }

  it 'should pass when an upload occurs' do
    expect {
      client.put_object(bucket: 'foo', key: 'bar/baz.qux', body: noise)
    }.to upload
  end

  it 'should fail when no upload occurs' do
    expect { }.to_not upload
  end

  it 'should pass when a matching upload occurs' do
    expect {
      client.put_object(bucket: 'foo', key: 'bar/baz.qux', body: noise)
    }.to upload(
      bucket: 'foo',
      key: 'bar/baz.qux',
      body: noise,
    )
  end

  it 'should pass when a single-write upload occurs' do
    expect {
      client.put_object(bucket: 'foo', key: 'bar/baz.qux') do |writer|
        writer.write(noise)
      end
    }.to upload(
      bucket: 'foo',
      key: 'bar/baz.qux',
      body: noise,
    )
  end

  it 'should pass when a multi-write upload occurs' do
    expect {
      client.put_object(bucket: 'foo', key: 'bar/baz.qux') do |writer|
        io = StringIO.new(noise)

        while chunk = io.read(256.bytes)
          writer.write(chunk)
        end
      end
    }.to upload(
      bucket: 'foo',
      key: 'bar/baz.qux',
      body: noise,
    )
  end

  it 'should pass when a upload occurs without a body' do
    expect {
      client.put_object(bucket: 'foo', key: 'bar/baz.qux')
    }.to upload(
      bucket: 'foo',
      key: 'bar/baz.qux',
    )
  end

  it 'should pass when all matching uploads occur' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo', body: 'foo')
      client.put_object(bucket: 'bar', key: 'bar/bar.bar', body: 'bar')
    }.to upload(
      { bucket: 'foo', key: 'foo/foo.foo', body: 'foo' },
      { bucket: 'bar', key: 'bar/bar.bar', body: 'bar' },
    )
  end

  it 'should pass when some matching uploads occur' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo', body: 'foo')
      client.put_object(bucket: 'bar', key: 'bar/bar.bar', body: 'bar')
      client.put_object(bucket: 'baz', key: 'baz/baz.baz', body: 'baz')
    }.to upload(
      { bucket: 'foo', key: 'foo/foo.foo', body: 'foo' },
      { bucket: 'bar', key: 'bar/bar.bar', body: 'bar' },
    )
  end

  it 'should fail when some matching uploads occur' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo', body: 'foo')
      client.put_object(bucket: 'bar', key: 'bar/bar.bar', body: 'bar')
    }.to_not upload(
      { bucket: 'foo', key: 'foo/foo.foo', body: 'foo' },
      { bucket: 'bar', key: 'bar/bar.bar', body: 'bar' },
      { bucket: 'baz', key: 'baz/baz.baz', body: 'baz' },
    )
  end

  it 'should fail when no matching uploads occur' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo', body: 'foo')
      client.put_object(bucket: 'bar', key: 'bar/bar.bar', body: 'bar')
    }.to_not upload(
      { bucket: 'baz', key: 'baz/baz.baz', body: 'baz' },
    )
  end

  it 'should pass for a matching bucket' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo') do |writer|
        writer.write('foo')
      end
    }.to upload(
      bucket: 'foo',
    )
  end

  it 'should pass for a matching key' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo') do |writer|
        writer.write('foo')
      end
    }.to upload(
      key: 'foo/foo.foo',
    )
  end

  it 'should pass for a matching body' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo') do |writer|
        writer.write('foo')
      end
    }.to upload(
      body: 'foo',
    )
  end

  it 'should fail when a different upload occurs' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo') do |writer|
        writer.write('foo')
      end
    }.not_to upload(
      bucket: 'bar',
      key: 'bar/bar.bar',
      body: 'bar',
    )
  end

  it 'should fail for a different bucket' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo') do |writer|
        writer.write('foo')
      end
    }.not_to upload(
      bucket: 'bar',
      key: 'foo/foo.foo',
      body: 'foo',
    )
  end

  it 'should fail for a different key' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo') do |writer|
        writer.write('foo')
      end
    }.not_to upload(
      bucket: 'foo',
      key: 'bar/bar.bar',
      body: 'foo',
    )
  end

  it 'should fail for a different body' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo', body: 'foo')
    }.not_to upload(
      bucket: 'foo',
      key: 'foo/foo.foo',
      body: 'bar',
    )
  end

  it 'should fail for a different writer' do
    expect {
      client.put_object(bucket: 'foo', key: 'foo/foo.foo') do |writer|
        writer.write('foo')
      end
    }.not_to upload(
      bucket: 'foo',
      key: 'foo/foo.foo',
      body: 'bar',
    )
  end

  it 'should fail when no upload occurs' do
    expect { }.not_to upload(
      bucket: 'foo',
      key: 'bar/baz.qux',
      body: 'foo',
    )
  end

  it 'should match regex without block' do
    expect {
      client.put_object(bucket: 'foo', key: 'bar/baz.qux', body: 'quxx')
    }.to upload(
      bucket: /foo/,
      key: %r{bar/baz.qux},
      body: /quxx/,
    )
  end

  it 'should match regex with block' do
    expect {
      client.put_object(bucket: 'foo', key: 'bar/baz.qux') do |writer|
        writer.write('quxx')
      end
    }.to upload(
      bucket: /foo/,
      key: %r{bar/baz.qux},
      body: /quxx/,
    )
  end
end
