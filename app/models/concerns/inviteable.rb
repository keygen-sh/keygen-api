module Inviteable
  extend ActiveSupport::Concern
  include Tokenable

  included do
    include AASM

    aasm column: :invite_state, whiny_transitions: false do
      state :uninvited, initial: true
      state :invited
      state :accepted

      event :send_invitation do
        transitions from: :uninvited, to: :invited, after: -> {
          send_invite_email
        }
      end

      event :accept_invitation do
        transitions from: :invited, to: :accepted, after: -> {
          # self.invite_sent_at = nil
          # self.invite_token   = nil
          # save
        }
      end
    end
  end

  def send_invite_email
    token, enc = generate_encrypted_token :invite_token do |token|
      "#{id.delete "-"}.#{token}"
    end

    self.invite_sent_at = Time.zone.now
    self.invite_token   = enc
    save

    AccountMailer.beta_invitation(account: self, token: token).deliver_later
  rescue Redis::CannotConnectError
    false
  end

  def beta_user?
    invite_state.to_sym == :accepted
  end
end
