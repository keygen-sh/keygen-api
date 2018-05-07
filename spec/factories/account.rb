FactoryGirl.define do
  factory :account do
    name { Faker::Company.name }
    slug { [Faker::Internet.domain_word, SecureRandom.hex].join }

    users []
    billing
    plan

    before :create do |account|
      account.users << build(:admin, account: account)

      account.accepted_comms = true unless account.accepted_comms.present?
      account.accepted_comms_at = Time.current unless account.accepted_comms_at.present?
      account.accepted_comms_rev = Account::CURRENT_COMMS_REV unless account.accepted_comms_rev.present?

      account.accepted_tos = true unless account.accepted_tos.present?
      account.accepted_tos_at = Time.current unless account.accepted_tos_at.present?
      account.accepted_tos_rev = Account::CURRENT_TOS_REV unless account.accepted_tos_rev.present?

      account.accepted_pp = true unless account.accepted_pp.present?
      account.accepted_pp_at = Time.current unless account.accepted_pp_at.present?
      account.accepted_pp_rev = Account::CURRENT_PP_REV unless account.accepted_pp_rev.present?

      account.save
    end
  end
end
