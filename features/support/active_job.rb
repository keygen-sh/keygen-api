# frozen_string_literal: true

require 'active_job'

class ActiveJob::Base
  # HACK(ezekg) when performing jobs inline during tests, we want to do
  #             so in a separate thread, otherwise we:
  #
  #             1. hit issues with connection roles, i.e. the :reading role,
  #                because jobs typically need to write.
  #             2. hit false-positives with bullet due to e.g. cascading
  #                destroy async jobs.
  #
  #             running everything in a separate thread solves these.
  around_perform do |job, block|
    case queue_adapter
    in ActiveJob::QueueAdapters::TestAdapter
      Thread.new do
        Rails.application.executor.wrap do
          ActiveRecord::Base.connection_pool.with_connection(&block)
        end
      end.join
    else
      block.call
    end
  end
end
