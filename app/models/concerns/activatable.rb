module Activatable
  extend ActiveSupport::Concern
  include Tokenable

  included do
    before_create :create_activation_token
  end

  def send_activation
    self.activation_sent_at = Time.zone.now
    create_activation_token
    save

    users.select { |u| u.has_role? :admin }.each do |admin|
      UserMailer.account_activation(admin).deliver_later
    end
  end

  def reset_activation_token!
    create_activation_token
    save
  end

  def activated?
    activated
  end

  private

  def create_activation_token
    self.activation_token = generate_token :activation_token
  end
end
