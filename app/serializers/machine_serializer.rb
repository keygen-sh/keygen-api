class MachineSerializer < BaseSerializer
  type :machines

  attributes [
    :id,
    :fingerprint,
    :name,
    :ip,
    :hostname,
    :platform,
    :created,
    :updated
  ]

  belongs_to :account
  belongs_to :license
  belongs_to :user
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
#
# Indexes
#
#  index_machines_on_account_id  (account_id)
#  index_machines_on_license_id  (license_id)
#
