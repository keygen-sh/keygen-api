class Group < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account

  has_many :licenses, -> { where(member_type: License.name) },
    class_name: 'GroupMember'
  has_many :users, -> { where(member_type: User.name) },
    class_name: 'GroupMember'
  has_many :machines, -> { where(member_type: Machine.name) },
    class_name: 'GroupMember'
  has_many :members,
    class_name: 'GroupMember'
  has_many :owners,
    class_name: 'GroupOwner'

  validates :account,
    presence: true
end
