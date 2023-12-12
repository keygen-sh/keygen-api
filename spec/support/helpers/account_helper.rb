# frozen_string_literal: true

# NOTE(ezekg) This is used as a sentinel value during tests to determine
#             whether or not a factory's account should run through
#             the default flow vs an explicit nil value given during
#             factory initialization.
NIL_ACCOUNT = Account.new(id: nil, slug: 'FOR_TEST_EYES_ONLY').freeze
