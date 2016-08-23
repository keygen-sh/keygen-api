class Machine < ApplicationRecord
  belongs_to :account
  belongs_to :license
  belongs_to :user

  validates :account, presence: { message: "must exist" }
  validates :license, presence: { message: "must exist" }
  validates :user, presence: { message: "must exist" }

  validates :fingerprint, presence: true, blank: false,
    uniqueness: { scope: :license_id }
  validates :name, presence: true, allow_nil: true,
    uniqueness: { scope: :license_id }

  scope :license, -> (id) {
    where license: License.find_by_hashid(id)
  }
  scope :user, -> (id) {
    where user: User.find_by_hashid(id)
  }
  scope :page, -> (page = {}) {
    paginate(page[:number]).per page[:size]
  }
end
