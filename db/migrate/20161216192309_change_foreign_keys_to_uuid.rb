class ChangeForeignKeysToUuid < ActiveRecord::Migration[5.0]

  def up
    id_to_uuid :accounts, :plan, [:plan]
    id_to_uuid :billings, :account, [:account]
    id_to_uuid :keys, :policy, [:policy]
    id_to_uuid :keys, :account, [:account]
    id_to_uuid :licenses, :user, [:user]
    id_to_uuid :licenses, :policy, [:policy]
    id_to_uuid :licenses, :account, [:account]
    id_to_uuid :machines, :account, [:account]
    id_to_uuid :machines, :license, [:license]
    id_to_uuid :policies, :product, [:product]
    id_to_uuid :policies, :account, [:account]
    id_to_uuid :products, :account, [:account]
    id_to_uuid :receipts, :billing, [:billing]
    id_to_uuid :roles, :resource, [:user, :product]
    id_to_uuid :tokens, :bearer, [:user, :product]
    id_to_uuid :tokens, :account, [:account]
    id_to_uuid :users, :account, [:account]
    id_to_uuid :webhook_endpoints, :account, [:account]
    id_to_uuid :webhook_events, :account, [:account]
  end

  private

  def id_to_uuid(table_name, relation_name, relation_classes)
    table_name = table_name.to_sym
    klass = table_name.to_s.classify.constantize
    foreign_key = "#{relation_name}_id".to_sym
    new_foreign_key = "#{relation_name}_uuid".to_sym

    add_column table_name, new_foreign_key, :uuid

    klass.where.not(foreign_key => nil).each do |record|
      relation_classes.map { |r| r.to_s.classify.constantize }.each do |relation_class|
        if associated_record = relation_class.find_by(id: record.send(foreign_key))
          record.update_column(new_foreign_key, associated_record.uuid)
        end
      end
    end

    remove_column table_name, foreign_key
    rename_column table_name, new_foreign_key, foreign_key
  end
end
