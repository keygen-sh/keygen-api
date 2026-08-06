# frozen_string_literal: true

namespace :online_cutover do
  desc 'print current status'
  task status: :environment do
    status = OnlineCutover.status

    puts "phase:           #{status[:phase]}"
    puts "routing:         #{status[:routing]}"
    puts "started:         #{status[:started]}"
    puts "quiesce timeout: #{status[:quiesce_timeout].to_i}s"
  end

  desc 'set quiescing phase - blocks new work'
  task quiesce: :environment do
    if OnlineCutover.current_phase.quiescing?
      puts 'already in quiescing phase.'

      exit 0
    end

    puts 'setting phase to quiescing...'

    OnlineCutover.set_phase!(OnlineCutover::PHASE_QUIESCING)

    puts "phase is now: #{OnlineCutover.current_phase}"
    puts
    puts 'new requests/jobs will now block before acquiring database connections. next:'
    puts
    puts '1. wait for existing work to complete'
    puts '2. wait for replication lag to be 0'
    puts '3. perform the database promotion'
    puts
    puts 'after promotion, run: rake online_cutover:promote'
  end

  desc 'set promoted routing - all traffic routed to promoted replica'
  task promote: :environment do
    unless OnlineCutover.current_phase.quiescing?
      warn "WARNING: system is not in quiescing phase (current: #{OnlineCutover.current_phase})"
      exit 1
    end

    puts 'setting routing to promoted...'

    OnlineCutover.set_routing!(OnlineCutover::ROUTING_PROMOTED)

    puts "routing is now: #{OnlineCutover.current_routing}"
    puts
    puts 'all database traffic now routes to the promoted replica.'
    puts
    puts 'to resume normal traffic, run: rake online_cutover:resume'
  end

  desc 'resume normal operations on promoted database'
  task resume: :environment do
    unless OnlineCutover.current_routing.promoted?
      warn "WARNING: system is not in promoted routing (current: #{OnlineCutover.current_routing})"
      exit 1
    end

    puts 'resuming traffic...'

    OnlineCutover.set_phase!(OnlineCutover::PHASE_NORMAL)

    puts "phase is now: #{OnlineCutover.current_phase}"
    puts
    puts 'traffic has resumed. Cutover complete.'
  end

  desc 'abort cutover - all traffic routed to primary'
  task abort: :environment do
    puts 'aborting cutover...'

    OnlineCutover.set_routing!(OnlineCutover::ROUTING_ABORTED)
    OnlineCutover.set_phase!(OnlineCutover::PHASE_NORMAL)

    puts "routing is now: #{OnlineCutover.current_routing}"
    puts "phase is now: #{OnlineCutover.current_phase}"
    puts
    puts 'cutover aborted. All traffic routed to primary.'
    puts 'the replica will NOT be used.'
  end

  desc 'reset cutover - write traffic routed to primary with reads routed to replica'
  task reset: :environment do
    puts 'resetting cutover state...'

    OnlineCutover.set_routing!(OnlineCutover::ROUTING_NORMAL)
    OnlineCutover.set_phase!(OnlineCutover::PHASE_NORMAL)

    puts 'state reset to defaults (phase: normal, routing: normal).'
  end
end
