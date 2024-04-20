class AddProductIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  def up
    log_level_was, ActiveRecord::Base.logger.level = ActiveRecord::Base.logger.level, Logger::DEBUG

    add_check_constraint :licenses, 'product_id IS NOT NULL', name: 'licenses_product_id_not_null', validate: false
  ensure
    ActiveRecord::Base.logger.level = log_level_was
  end
end
