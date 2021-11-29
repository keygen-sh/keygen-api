# frozen_string_literal: true

desc 'send a stdout issue'
namespace :stdout do
  namespace :send do
    task zero: [:environment] do
      subscribers = User.stdout_subscribers
                        .where('stdout_last_sent_at is null or stdout_last_sent_at < ?', 7.days.ago)
                        .select(:id, :email, :first_name)
                        .to_a

      Keygen.logger.info "Sending zeroth issue to #{subscribers.size} Stdout subscribers"

      subscribers.each do |subscriber|
        subscriber.touch(:stdout_last_sent_at)

        Keygen.logger.info "Sending issue #0 to #{subscriber.email}"

        StdoutMailer.issue_zero(subscriber: subscriber)
                    .deliver_later(
                      # Fan out deliveries
                      in: rand(1.minute..3.hours),
                    )

        sleep 0.1
      end

      Keygen.logger.info "Done"
    end
  end
end
