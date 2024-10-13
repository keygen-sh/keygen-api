# frozen_string_literal: true

if Regexp.respond_to?(:timeout)
  Regexp.timeout = 1
end
