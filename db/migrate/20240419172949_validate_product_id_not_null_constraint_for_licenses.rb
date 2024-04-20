class ValidateProductIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  def up
    log_level_was, ActiveRecord::Base.logger.level = ActiveRecord::Base.logger.level, Logger::DEBUG

    validate_check_constraint :licenses, name: 'licenses_product_id_not_null'
  ensure
    ActiveRecord::Base.logger.level = log_level_was
  end
end
