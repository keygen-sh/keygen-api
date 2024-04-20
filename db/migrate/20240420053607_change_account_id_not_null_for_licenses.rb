class ChangeAccountIdNotNullForLicenses < ActiveRecord::Migration[7.1]
  def up
    log_level_was, ActiveRecord::Base.logger.level = ActiveRecord::Base.logger.level, Logger::DEBUG

    change_column_null :licenses, :account_id, false
    remove_check_constraint :licenses, name: 'licenses_account_id_not_null'
  ensure
    ActiveRecord::Base.logger.level = log_level_was
  end
end
