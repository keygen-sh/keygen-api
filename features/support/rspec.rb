# frozen_string_literal: true

require 'cucumber/rspec/doubles'
require 'rspec/expectations'

# set this so that long strings e.g. HTML/JSON are not truncated in failure diffs
RSpec::Expectations.configuration.max_formatted_output_length = nil
