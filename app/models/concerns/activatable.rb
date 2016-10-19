module Activatable
  extend ActiveSupport::Concern
  include Tokenable

  def send_activation_email
    token, enc = generate_encrypted_token :activation_token

    self.activation_sent_at = Time.zone.now
    self.activation_token   = enc
    save

    users.admins.each do |admin|
      UserMailer.account_activation(admin, token).deliver_later
    end
  end

  def activated?
    activated
  end
end
