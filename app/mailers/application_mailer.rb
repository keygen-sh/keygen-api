# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  DEFAULT_FROM_EMAIL = ENV.fetch('KEYGEN_FROM_EMAIL') { 'noreply@keygen.sh' }
                          .freeze

  default from: "Keygen Support <#{DEFAULT_FROM_EMAIL}>"
  default precedence: 'normal'
end
