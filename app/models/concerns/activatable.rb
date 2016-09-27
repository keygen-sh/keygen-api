module Activatable
  extend ActiveSupport::Concern

  included do
    before_create :create_activation_token
  end

  def send_activation
    self.activation_sent_at = Time.zone.now
    create_activation_token
    save

    self.users.where(role: "admin").each do |admin|
      UserMailer.account_activation(admin).deliver_later
    end
  end

  def reset_activation_token!
    create_activation_token
    save
  end

  private

  def create_activation_token
    self.activation_token = generate_token :activation_token
  end
end
