# frozen_string_literal: true

require 'securerandom'
require 'sidekiq'
require 'sidekiq/capsule'
require 'sidekiq/fetch'

module PerformBulk
  LOG_PREFIX       = :perform_bulk
  QUEUE_PREFIX     = 'perform_bulk:'
  QUEUE_WAITING    = QUEUE_PREFIX + 'waiting'    # the queue used for unbatched bulk jobs
  QUEUE_PROCESSING = QUEUE_PREFIX + 'processing' # the queue used for batched bulk jobs
  QUEUE_RUNNING    = QUEUE_PREFIX + 'running'    # the queue used for executing bulk jobs
  QUEUE_DEFAULT    = 'default'                   # the default sidekiq queue

  # Including PerformBulk::Job allows a Sidekiq::Job to opt into bulk processing,
  # where the bulk fetcher dequeues multiple jobs and batches them into a
  # single job execution, where the job accepts a splat of args.
  #
  # e.g. if we have an existing AuditLog job:
  #
  #   class AuditLogJob
  #     include Sidekiq::Job
  #
  #     def perform(log_attributes)
  #       AuditLog.create(log_attributes)
  #     end
  #   end
  #
  # But after awhile, this job has high throughput, and we'd greatly benefit
  # from bulk inserting such simple log rows.
  #
  # We can modify it to be a bulk job:
  #
  #   class AuditLogJob
  #     include Sidekiq::Job
  #     include PerformBulk::Job
  #
  #     def perform(*logs_attributes)
  #       AuditLog.insert_all(logs_attributes)
  #     end
  #   end
  #
  # We can queue jobs normally, but during times of high throughput, they'll
  # be batched up according to job class and executed in bulk:
  #
  #   25.times do
  #     AuditLogJob.perform_async('id' => ...)
  #   end
  #
  # The above will result in a single job execution, where the splat of job
  # args are the combined args of the 25 batched jobs.
  module Job
    def self.included(klass)
      raise ArgumentError, "cannot be used outside of Sidekiq job (got #{klass.ancestors})" unless
        klass < Sidekiq::Job

      klass.extend ClassMethods

      # NB(ezekg) swap the bulk job's queue over to our capsule's ingress queue in
      #           case our job doesn't ever call .sidekiq_options
      klass.sidekiq_options queue: QUEUE_WAITING
    end

    module ClassMethods
      # FIXME(ezekg) there's gotta be a better way to do this?
      def sidekiq_options(...)
        opts = super(...)

        # hijack bulk job to push new jobs to our capsule's ingress queue, and
        # then we'll push to the expected egress queue after batching.
        unless opts['queue'] == QUEUE_WAITING
          queue_was  = opts.delete('queue') || QUEUE_DEFAULT
          queue      = QUEUE_WAITING

          Logger.instance.debug(src: :job) { "hijacking #{name.inspect} from #{queue_was.inspect} to #{queue.inspect}" }

          opts['queue_was'] = queue_was
          opts['queue']     = queue
        end

        opts
      end
    end
  end

  class Logger
    include Singleton

    %i[debug info warn error fatal].each do |level|
      define_method(level) do |*msgs, **tags, &block|
        log(level, *msgs, **tags, &block)
      end
    end

    private

    def log(level, *msgs, **tags, &block)
      Sidekiq::Context.with(src: [LOG_PREFIX, tags.delete(:src)].compact.join('.'), **tags) do
        Sidekiq.logger.send(level, *msgs, &block)
      end
    end
  end

  module Logging
    class Chain
      def initialize(**tags) = @default_tags = tags.freeze

      %i[debug info warn error fatal].each do |level|
        define_method(level) do |*msgs, **tags, &block|
          Logger.instance.send(level, *msgs, **default_tags.merge(tags), &block)
        end
      end

      private

      attr_reader :default_tags
    end

    def self.[](src, **)
      Module.new do
        include Logging

        define_method :logger do
          @_logger ||= Logging::Chain.new(**, src:)
        end

        private :logger
      end
    end

    private

    def logger = Logger.instance
  end

  class Processor
    include Sidekiq::Job
    include Logging[:processor]

    sidekiq_options queue: QUEUE_PROCESSING

    def perform(*batch)
      batch.group_by { it['class'] }.each do |class_name, job_hashes|
        args = job_hashes.collect { it['args'] }

        # NB(ezekg) for a better DX we'll unwrap jobs with a singular arg
        if args.all?(&:one?)
          args = args.reduce(&:concat)
        end

        logger.debug { "batching #{job_hashes.size} #{class_name.inspect} jobs" }

        Runner.set(display_class: "#{Runner.name}[#{class_name}, #{args.size}]")
              .perform_async(class_name, args)
      end
    end
  end

  class Runner
    include Sidekiq::Job
    include Logging[:runner]

    sidekiq_options queue: QUEUE_RUNNING

    def perform(class_name, args)
      klass   = Object.const_get(class_name)
      options = klass.sidekiq_options_hash || {}
      queue   = options['queue_was'] || QUEUE_DEFAULT

      logger.debug { "executing batch of #{args.size} jobs on queue: #{queue.inspect}" }

      klass.set(queue:, display_class: "#{class_name}[#{args.size}]")
           .perform_async(*args)
    end
  end

  # NB(ezekg) this conforms to the interface of Sidekiq's UnitOfWork struct
  UnitOfWork = Struct.new(:queue, :jobs, :config) do
    def queue_name  = queue.delete_prefix('queue:')
    def acknowledge = nil # nothing to do

    # jit-compute singular egress batch job
    def job = @job ||= begin
      now        = Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)
      class_name = PerformBulk::Processor.name

      Sidekiq.dump_json(
        'display_class' => "#{class_name}[#{jobs.size}]",
        'class' => class_name,
        'jid' => SecureRandom.hex(12),
        'queue' => QUEUE_PROCESSING,
        'args' => Sidekiq.load_json('[' + jobs.join(',') + ']'), # NB(ezekg) optimized single-pass parse
        'created_at' => now,
        'enqueued_at' => now,
        'retry' => true,
      )
    end

    def requeue
      config.redis { it.rpush(queue, *jobs) }
    end
  end

  class BulkFetch < Sidekiq::BasicFetch
    DEFAULT_BATCH_SIZE = 100

    include Logging[:bulk_fetch]

    attr_reader :batch_size

    def initialize(capsule)
      super(capsule)

      @batch_size = capsule.config[:bulk_batch_size] || DEFAULT_BATCH_SIZE
    end

    def retrieve_work
      queue = "queue:#{QUEUE_WAITING}"
      batch = config.redis { it.rpop(queue, batch_size) } # TODO(ezekg) make reliable?

      if batch.blank?
        logger.debug { "no bulk work - sleeping for #{TIMEOUT}..." }

        sleep TIMEOUT

        return nil
      end

      logger.debug { "batching #{batch.size} bulk jobs: #{batch}" }

      UnitOfWork.new(jobs: batch, queue:, config:)
    end

    def bulk_requeue(processing)
      return if processing.empty?

      logger.debug { "requeueing #{processing.size} terminated bulk jobs: #{processing}" }

      requeue = processing.reduce({}) do |hash, uow|
        hash[uow.queue] ||= []
        hash[uow.queue].concat(uow.jobs)
        hash
      end

      redis do |conn|
        conn.pipelined do |pipeline|
          requeue.each do |queue, jobs|
            pipeline.rpush(queue, *jobs)
          end
        end
      end

      logger.info { "pushed #{processing.size} bulk jobs back to redis" }
    rescue => e
      logger.warn { "failed to requeue #{processing.size} bulk jobs: #{e.message}" }
    end
  end

  def self.bulk_fetch!(config, fetch_concurrency: 1, work_concurrency: 5, batch_size: 100)
    config.capsule(QUEUE_WAITING) do |cap|
      cap.config[:bulk_batch_size] = batch_size

      cap.queues      = [QUEUE_WAITING] # TODO(ezekg) would be nice to have per-job queues
      cap.concurrency = fetch_concurrency

      # FIXME(ezekg) sidekiq does not support capsule-local config like cap.config[:fetch_class] = BulkFetch
      cap.fetcher = BulkFetch.new(cap)
    end

    config.capsule(QUEUE_PROCESSING) do |cap|
      cap.queues      = [QUEUE_PROCESSING]
      cap.concurrency = work_concurrency
    end

    config.capsule(QUEUE_RUNNING) do |cap|
      cap.queues      = [QUEUE_RUNNING]
      cap.concurrency = work_concurrency
    end
  end

  module CapsuleExtension
    # FIXME(ezekg) hack because sidekiq capsules mutate global config
    def fetcher=(instance)
      @fetcher = instance
    end
  end

  Sidekiq::Capsule.prepend(CapsuleExtension)
end
