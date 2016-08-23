class MachineSerializer < BaseSerializer
  type :machines

  attributes [
    :id,
    :fingerprint,
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
