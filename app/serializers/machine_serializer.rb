class MachineSerializer < BaseSerializer
  type :machines

  attributes :id,
             :fingerprint,
             :name,
             :ip,
             :hostname,
             :platform,
             :metadata,
             :created,
             :updated
end

# == Schema Information
#
# Table name: machines
#
#  fingerprint :string
#  ip          :string
#  hostname    :string
#  platform    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  deleted_at  :datetime
#  metadata    :jsonb
#  id          :uuid             not null, primary key
#  account_id  :uuid
#  license_id  :uuid
#
# Indexes
#
#  index_machines_on_account_id  (account_id)
#  index_machines_on_created_at  (created_at)
#  index_machines_on_deleted_at  (deleted_at)
#  index_machines_on_id          (id)
#  index_machines_on_license_id  (license_id)
#
