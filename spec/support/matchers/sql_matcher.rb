# frozen_string_literal: true

RSpec::Matchers.define :match_sql do |expected|
  # NOTE(ezekg) Make our expected SQL string match #to_sql format.
  #             This mostly deals with formatting parentheses.
  expected = expected.dup.tap do |s|
    s.squish!
    s.gsub!(/(\()\s*([\w'"])/, '\1\2')     # `( "table"."column"` => `("table"."column"`
    s.gsub!(/([\w"'])\s*(\))/, '\1\2')     # `"table"."column" = 'value')` => `"table"."column" = 'value')`
    s.gsub!(/\s+(\()\s+(\()\s+/, ' \1\2 ') # ` ( ( ` => ` (( `
    s.gsub!(/\s+(\))\s+(\))\s+/, ' \1\2 ') # ` ) ) ` => ` )) `
  end

  match do |actual|
    actual == expected
  end

  failure_message do |actual|
    <<~MSG
      Expected SQL to match:
        expected:
          #{expected}
        got:
          #{actual}
    MSG
  end
end
