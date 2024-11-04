# frozen_string_literal: true

require 'memory_profiler'

RSpec::Matchers.define :allocate_less_than do |bytes|
  supports_block_expectations

  match do |block|
    @expected = bytes.to_i

    report = MemoryProfiler.report(ignore_files: /rspec/) do
      # NOTE(ezekg) reenable GC because profiler disables it but we want
      #             to measure memory consumption under normal load, i.e.
      #             we don't care about total memory consumed w/o GC,
      #             but rather total memory footprint w/ GC.
      GC.enable

      block.call
    end

    @actual = report.total_allocated_memsize.to_i

    @actual < @expected
  end

  failure_message do
    "Expected block to allocate less than #{@expected.to_fs(:delimited)} byte(s), but allocated #{@actual.to_fs(:delimited)} byte(s)"
  end

  failure_message_when_negated do
    "Expected block to allocate at least #{@expected.to_fs(:delimited)} byte(s), but allocated #{@actual.to_fs(:delimited)} byte(s)"
  end
end

RSpec::Matchers.define_negated_matcher :allocate_at_least, :allocate_less_than
