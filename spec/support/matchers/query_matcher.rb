# frozen_string_literal: true

# FIXME(ezekg) There doesn't seem to be an elegant way of making an RSpec
#              matcher that accepts a block, e.g.:
#
#                  expect { ... }.to match_queries { ... }
#
#              From what I gathered, this is the best way...
def match_queries(...) = QueryMatcher.new(...)
def match_query(...)   = match_queries(...)

class QueryMatcher
  def initialize(count: nil, &block)
    @count = count
    @block = block
  end

  def supports_block_expectations? = true
  def supports_value_expectations? = true

  def matches?(block)
    @queries = QueryLogger.log(&block)

    (@count.nil? || @queries.size == @count) && (
      @block.nil? || @block.call(@queries)
    )
  end

  def failure_message
    "expected to match #{@count} queries but got #{@queries.size}"
  end

  def failure_message_when_negated
    "expected to not match #{@count} queries"
  end

  private

  class QueryLogger
    IGNORED_STATEMENTS = %w[CACHE SCHEMA]
    IGNORED_QUERIES    = %r{^(?:ROLLBACK|BEGIN|COMMIT|SAVEPOINT|RELEASE)}
    IGNORED_COMMENTS   = %r{
      /\*(\w+='\w+',?)+\*/ # query log tags
    }x

    def initialize
      @queries = []
    end

    def self.log(&) = new.log(&)
    def log(&block)
      ActiveSupport::Notifications.subscribed(
        logger_proc,
        'sql.active_record',
        &proc {
          result = block.call
          result.load if result in ActiveRecord::Relation # autoload relations
        }
      )

      @queries
    end

    private

    def logger_proc = proc(&method(:logger))
    def logger(event)
      unless IGNORED_STATEMENTS.include?(event.payload[:name]) || IGNORED_QUERIES.match(event.payload[:sql])
        query = event.payload[:sql].gsub(IGNORED_COMMENTS, '')
                                   .squish

        @queries << query
      end
    end
  end
end
