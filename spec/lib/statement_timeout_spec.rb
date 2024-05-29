# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'statement_timeout'

describe StatementTimeout do
  context 'with a duration' do
    it 'should set a local statement_timeout' do
      expect { License.statement_timeout(1.minute) { License.unscoped.take } }.to(
        match_queries(count: 2) do |queries|
          expect(queries.first).to eq <<~SQL.squish
            SET LOCAL statement_timeout = 60000
          SQL

          expect(queries.second).to eq <<~SQL.squish
            SELECT "licenses".* FROM "licenses" LIMIT 1
          SQL
        end
      )
    end
  end

  context 'with an integer' do
    it 'should set a local statement_timeout' do
      expect { License.statement_timeout(1000) { License.unscoped.take } }.to(
        match_queries(count: 2) do |queries|
          expect(queries.first).to eq <<~SQL.squish
            SET LOCAL statement_timeout = 1000
          SQL

          expect(queries.second).to eq <<~SQL.squish
            SELECT "licenses".* FROM "licenses" LIMIT 1
          SQL
        end
      )
    end
  end

  context 'with a float' do
    it 'should set a local statement_timeout' do
      expect { License.statement_timeout(1000.5) { License.unscoped.take } }.to(
        match_queries(count: 2) do |queries|
          expect(queries.first).to eq <<~SQL.squish
            SET LOCAL statement_timeout = 1000.5
          SQL

          expect(queries.second).to eq <<~SQL.squish
            SELECT "licenses".* FROM "licenses" LIMIT 1
          SQL
        end
      )
    end
  end

  context 'with a string' do
    it 'should set a local statement_timeout' do
      expect { License.statement_timeout('1s') { License.unscoped.take } }.to(
        match_queries(count: 2) do |queries|
          expect(queries.first).to eq <<~SQL.squish
            SET LOCAL statement_timeout = '1s'
          SQL

          expect(queries.second).to eq <<~SQL.squish
            SELECT "licenses".* FROM "licenses" LIMIT 1
          SQL
        end
      )
    end
  end
end
