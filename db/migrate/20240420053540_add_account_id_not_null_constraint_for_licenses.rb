class AddAccountIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  def up
    log_level_was, ActiveRecord::Base.logger.level = ActiveRecord::Base.logger.level, Logger::DEBUG

    add_check_constraint :licenses, 'account_id IS NOT NULL', name: 'licenses_account_id_not_null', validate: false
  ensure
    ActiveRecord::Base.logger.level = log_level_was
  end
end
