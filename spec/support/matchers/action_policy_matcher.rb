# frozen_string_literal: true

RSpec::Matchers.define :authorize do |action|
  match do |policy|
    policy.apply("#{action}?")
  rescue ActionPolicy::Unauthorized
    false
  end

  failure_message do |policy|
    reasons = policy.result.reasons
    bearer  = policy.bearer
    record  = policy.record

    "#{policy.class} did not allow #{action}? on #<#{record.class}:#{record.id}> for #<#{bearer.class}:#{bearer.id}> because #{reasons.reasons}."
  end

  failure_message_when_negated do |policy|
    reasons = policy.result.reasons
    bearer  = policy.bearer
    record  = policy.record

    "#{policy.class} did not deny #{action}? on #<#{record.class}:#{record.id}> for #<#{bearer.class}:#{bearer.id}> because #{reasons.reasons}."
  end
end
