# frozen_string_literal: true

require 'anbt-sql-formatter/formatter'

rule = AnbtSql::Rule.new
rule.keyword = AnbtSql::Rule::KEYWORD_UPPER_CASE
%w[count sum substr date].each { rule.function_names << _1.upcase }
rule.indent_string = '  '
formatter = AnbtSql::Formatter.new(rule)

RSpec::Matchers.define :match_sql do |expected|
  attr_reader :actual, :expected

  diffable

  match do |actual|
    @expected = formatter.format(+expected.to_s)
    @actual   = formatter.format(+actual.to_s)

    @actual == @expected
  end

  failure_message do |actual|
    <<~MSG
      Expected SQL to match:
        expected:
          #{@expected.squish}
        got:
          #{@actual.squish}
    MSG
  end
end
