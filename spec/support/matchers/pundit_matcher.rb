# frozen_string_literal: true

RSpec::Matchers.define :permit do |action|
  match do |policy|
    if policy.is_a?(Proc)
      policy.call
    else
      policy.public_send("#{action}?")
    end
  rescue Pundit::NotAuthorizedError
    false
  end

  failure_message do |policy|
    "#{policy.class} does not permit #{action} on #{policy.resource.inspect} for #{policy.context.inspect}."
  end

  failure_message_when_negated do |policy|
    "#{policy.class} does not deny #{action} on #{policy.resource.inspect} for #{policy.context.inspect}."
  end

  supports_block_expectations
end
