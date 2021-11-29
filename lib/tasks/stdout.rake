# frozen_string_literal: true

desc 'send a stdout issue'
namespace :stdout do
  namespace :send do
    task zero: [:environment] do
      subscribers = User.stdout_subscribers
                        .select(:email, :first_name)
                        .to_a

      Keygen.logger.info "Sending zeroth issue to all Stdout subscribers (#{subscribers.size})"

      subscribers.each do |subscriber|
        Keygen.logger.info "Sending issue #0 to #{subscriber}"

        StdoutMailer.issue_zero(subscriber: subscriber)
                    .deliver_later(
                      # Fan out deliveries
                      in: rand(1.minute..3.hours),
                    )
      end

      Keygen.logger.info "Done"
    end
  end
end
