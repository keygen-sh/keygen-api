# heroku run:detached -e BATCH_SIZE=100000 rails runner db/scripts/seed_overage_strategy_for_policies.rb --tail


Rails.logger.info "[scripts.seed_overage_strategy_for_policies] Starting"

Policy.where(concurrent: true)
      .update_all(overage_strategy: 'ALWAYS_ALLOW_OVERAGE')

Policy.where(concurrent: false)
      .update_all(overage_strategy: 'NO_OVERAGE')

Rails.logger.info "[scripts.seed_overage_strategy_for_policies] Done"
