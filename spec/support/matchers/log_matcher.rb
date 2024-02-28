# frozen_string_literal: true

RSpec::Matchers.define :log do |message|
  supports_block_expectations

  match do |block|
    @levels   ||= %i[error warn info debug]
    @expected ||= message
    @messages   = []

    @levels.each do |level|
      allow(Rails.logger).to(
        receive(level) { @messages << _1.strip }.and_return(nil),
      )
    end

    block.call

    expect(@messages).to be_any { |actual|
    expected = case @expected
               in String => s
                 /#{Regexp.escape(s)}/
               in Regexp => re
                 re
               end

      expected.match?(actual)
    }
  end

  chain :error do |message|
    @levels   = %i[error]
    @expected = message
  end

  chain :warning do |message|
    @levels   = %i[warn]
    @expected = message
  end

  chain :info do |message|
    @levels   = %i[info]
    @expected = message
  end

  chain :debug do |message|
    @levels   = %i[debug]
    @expected = message
  end

  failure_message do
    <<~MSG
      Expected block to output matching log messages to the following log levels: #{@levels.inspect}.
        expected:
          #{@expected.inspect}
        actual:
          #{@messages.join.inspect}
    MSG
  end
end
