# frozen_string_literal: true

class ScenarioDebugger
  DEBUG_ENV_KEYS        = %w[DEBUG PARALLEL_TEST_PROCESSORS TEST_ENV_NUMBER]
  DEBUG_MAX_BODY_SIZE   = 16.kilobytes
  DEBUG_BACKTRACE_DEPTH = 50

  def self.call(...) = new(...).call

  def initialize(scenario:, request:, response:)
    @scenario  = scenario
    @exception = request.env['action_dispatch.exception'] || scenario.exception
    @request   = ActionDispatch::Request.new(request.env)
    @response  = response
  end

  def call
    output = +"\n"
    output << format_scenario << "\n\n"
    output << format_exception << "\n\n"
    output << format_backtrace << "\n\n"
    output << format_request << "\n\n"
    output << format_response << "\n\n"
    output << format_env << "\n"
    output
  rescue => e
    "Debugger failed: #{e.inspect}"
  end

  private

  attr_reader :scenario,
              :exception,
              :request,
              :response

  def format_scenario
    lines = ["Scenario:"]
    lines << indent(scenario.location.to_s)

    lines.join("\n")
  end

  def format_exception
    lines = ["Exception:"]
    lines << indent("#{exception.class}: #{exception.message.inspect}")

    lines.join("\n")
  end

  def format_backtrace
    return "" if exception.backtrace.blank?

    lines = ["Backtrace:"]

    exception.backtrace.first(DEBUG_BACKTRACE_DEPTH).each do |line|
      lines << indent(line)
    end

    if exception.backtrace.size > DEBUG_BACKTRACE_DEPTH
      remainder = exception.backtrace.size - DEBUG_BACKTRACE_DEPTH

      lines << indent("... (#{remainder} more lines)")
    end

    lines.join("\n")
  end

  def format_request
    # FIXME(ezekg) how on God's green earth is there not an easier way to do this?
    headers = request.headers.each_with_object({}) do |(key, value), headers|
      next unless (key.start_with?('HTTP_') && key != 'HTTP_VERSION') ||
                  key == 'CONTENT_TYPE' || key == 'CONTENT_LENGTH'

      next if key == 'HTTP_COOKIE' && value.blank?

      canonical_key = key.sub(/^HTTP_/, '')
                         .split('_')
                         .map(&:capitalize)
                         .join('-')

      headers[canonical_key] = value
    end

    lines = ["Request:"]
    lines << indent("#{request.request_method} #{request.fullpath} #{request.version}")

    headers.sort.each do |key, value|
      lines << indent("#{key}: #{value}")
    end

    lines << "" # blank line
    lines << indent(format_body(request.body.string))

    lines.join("\n")
  end

  def format_response
    headers = response.headers

    lines = ["Response:"]
    lines << indent("#{request.version} #{response.status}")

    headers.sort.each do |key, value|
      lines << indent("#{key}: #{value}")
    end

    lines << ""
    lines << indent(format_body(response.body))

    lines.join("\n")
  end

  def format_env
    lines = ["Env:"]

    DEBUG_ENV_KEYS.sort.map do |key|
      lines << indent("#{key}=#{ENV[key].inspect}")
    end

    lines.join("\n")
  end

  def format_body(body)
    return "<no data>" if body.blank?

    begin
      json = JSON.parse(body)

      return truncate(JSON.pretty_generate(json), size: DEBUG_MAX_BODY_SIZE)
    rescue JSON::GeneratorError,
           JSON::ParserError
      # not json... continuing...
    end

    return "<binary data>" if
      body.encoding == Encoding::ASCII_8BIT || !body.valid_encoding?

    truncate(body.to_s, size: DEBUG_MAX_BODY_SIZE)
  end

  def indent(text, size: 2)
    text.each_line.map { " " * size + it }.join
  end

  def truncate(text, size: 80)
    return text unless text.size > size

    remainder = text.size - size
    lines     = [
      text.first(size / 2),
      "... (#{remainder} more chars)",
      text.last(size / 2),
    ]

    lines.join("\n")
  end
end
