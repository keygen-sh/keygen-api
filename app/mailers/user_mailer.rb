class UserMailer < ApplicationMailer

  def password_reset(user)
    @user = user
    mail :to => user.email, :subject => "Password Reset"
  end

  def account_activation(user)
    @user = user
    mail :to => user.email, :subject => "Account Activation"
  end
end
