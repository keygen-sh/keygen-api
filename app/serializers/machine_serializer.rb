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

  belongs_to :license
  has_one :product, through: :license
  has_one :user, through: :license
end

# == Schema Information
#
# Table name: machines
#
#  id          :integer          not null, primary key
#  fingerprint :string
#  ip          :string
#  hostname    :string
#  platform    :string
#  account_id  :integer
#  license_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  deleted_at  :datetime
#  metadata    :jsonb
#
# Indexes
#
#  index_machines_on_account_id_and_id           (account_id,id)
#  index_machines_on_deleted_at                  (deleted_at)
#  index_machines_on_fingerprint_and_account_id  (fingerprint,account_id)
#  index_machines_on_license_id_and_account_id   (license_id,account_id)
#
