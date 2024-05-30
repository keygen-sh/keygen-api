# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'statement_timeout'

describe StatementTimeout do
  before(:all) { DatabaseCleaner.strategy = nil } # vacuum doesn't support transactions
  after(:all)  { DatabaseCleaner.strategy = :transaction }

  subject { License }

  let(:connection) { subject.respond_to?(:lease_connection) ? subject.lease_connection : subject.connection }
  let(:table_name) { subject.table_name }

  context 'with a duration' do
    it 'should set a temporary statement_timeout for valid duration' do
      statement_timeout_was = connection.statement_timeout

      expect { subject.statement_timeout(1.minute) { subject.unscoped.take } }.to(
        match_queries(count: 3) do |queries|
          expect(queries.first).to eq <<~SQL.squish
            SET statement_timeout = 60000
          SQL

          expect(queries.second).to eq <<~SQL.squish
            SELECT "#{table_name}".* FROM "#{table_name}" LIMIT 1
          SQL

          expect(queries.third).to eq <<~SQL.squish
            SET statement_timeout = '#{statement_timeout_was}'
          SQL
        end
      )

      expect(connection.statement_timeout).to eq statement_timeout_was
    end
  end

  context 'with an integer' do
    it 'should set a temporary statement_timeout for valid integer' do
      statement_timeout_was = connection.statement_timeout

      expect { subject.statement_timeout(1000) { subject.unscoped.take } }.to(
        match_queries(count: 3) do |queries|
          expect(queries.first).to eq <<~SQL.squish
            SET statement_timeout = 1000
          SQL

          expect(queries.second).to eq <<~SQL.squish
            SELECT "#{table_name}".* FROM "#{table_name}" LIMIT 1
          SQL

          expect(queries.third).to eq <<~SQL.squish
            SET statement_timeout = '#{statement_timeout_was}'
          SQL
        end
      )

      expect(connection.statement_timeout).to eq statement_timeout_was
    end
  end

  context 'with a float' do
    it 'should set a temporary statement_timeout for valid float' do
      statement_timeout_was = connection.statement_timeout

      expect { subject.statement_timeout(1000.5) { subject.unscoped.take } }.to(
        match_queries(count: 3) do |queries|
          expect(queries.first).to eq <<~SQL.squish
            SET statement_timeout = 1000.5
          SQL

          expect(queries.second).to eq <<~SQL.squish
            SELECT "#{table_name}".* FROM "#{table_name}" LIMIT 1
          SQL

          expect(queries.third).to eq <<~SQL.squish
            SET statement_timeout = '#{statement_timeout_was}'
          SQL
        end
      )

      expect(connection.statement_timeout).to eq statement_timeout_was
    end
  end

  context 'with a string' do
    it 'should set a temporary statement_timeout for valid value' do
      statement_timeout_was = connection.statement_timeout

      expect { subject.statement_timeout('1s') { subject.unscoped.take } }.to(
        match_queries(count: 3) do |queries|
          expect(queries.first).to eq <<~SQL.squish
            SET statement_timeout = '1s'
          SQL

          expect(queries.second).to eq <<~SQL.squish
            SELECT "#{table_name}".* FROM "#{table_name}" LIMIT 1
          SQL

          expect(queries.third).to eq <<~SQL.squish
            SET statement_timeout = '#{statement_timeout_was}'
          SQL
        end
      )

      expect(connection.statement_timeout).to eq statement_timeout_was
    end

    it 'should raise for invalid value' do
      statement_timeout_was = connection.statement_timeout

      expect { subject.statement_timeout('foo') { subject.unscoped.take } }
        .to raise_error ActiveRecord::StatementInvalid

      expect(connection.statement_timeout).to eq statement_timeout_was
    end
  end

  it 'should not timeout' do
    expect { subject.statement_timeout('2s') { connection.execute('select pg_sleep(1)') } }
      .to_not raise_error
  end

  it 'should timeout' do
    expect { subject.statement_timeout('1s') { connection.execute('select pg_sleep(2)') } }
      .to raise_error ActiveRecord::StatementInvalid
  end

  it 'should return a relation' do
    expect(subject.statement_timeout('1s') { subject.all }).to be_an ActiveRecord::Relation
  end

  it 'should return a record' do
    expect(subject.statement_timeout('1s') { subject.new }).to be_a subject
  end

  it 'should return a value' do
    expect(subject.statement_timeout('1s') { connection.execute('select 1 as value')[0]['value'] }).to eq 1
  end

  it 'should support transaction' do
    expect { subject.statement_timeout('1s') { subject.transaction { subject.unscoped.take } } }
      .to_not raise_error
  end

  # NOTE(ezekg) We're explicitly testing VACUUM because it doesn't support
  #             transactions, and this asserts our implementation is
  #             compatible with such queries.
  it 'should support vacuum' do
    expect { subject.statement_timeout('1s') { connection.execute("VACUUM ANALYZE #{table_name}") } }
      .to_not raise_error
  end

  it 'should raise error' do
    expect { subject.statement_timeout('1s') { subject.transaction { connection.execute("VACUUM ANALYZE #{table_name}") } } }
      .to raise_error { |err|
        expect(err.message).to match /vacuum cannot run inside a transaction block/i
      }
  end
end
