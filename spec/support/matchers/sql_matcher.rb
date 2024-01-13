# frozen_string_literal: true

RSpec::Matchers.define :match_sql do |expected|
  match do |actual|
    # Make our SQL string match #to_sql. This mostly deals with formatting parentheses.
    actual == expected.squish
                      .gsub(/(\()\s*([\w'"])/, '\1\2')     # `( "table"."column"` => `("table"."column"`
                      .gsub(/([\w"'])\s*(\))/, '\1\2')     # `"table"."column" = 'value')` => `"table"."column" = 'value')`
                      .gsub(/\s+(\()\s+(\()\s+/, ' \1\2 ') # ` ( ( ` => ` (( `
                      .gsub(/\s+(\))\s+(\))\s+/, ' \1\2 ') # ` ) ) ` => ` )) `
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
