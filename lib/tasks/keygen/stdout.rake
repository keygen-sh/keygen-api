# frozen_string_literal: true

namespace :keygen do
  desc 'Send an issue of Stdout'
  namespace :stdout do
    namespace :send do
      task eleven: %i[environment] do
        subscribers = User.stdout_subscribers
                          .where('stdout_last_sent_at IS NULL OR stdout_last_sent_at < ?', 7.days.ago)
                          .select(:id, :email, :first_name)
                          .reorder(:email, :created_at)
                          .to_a

        Keygen.logger.info "Sending issue #11 to #{subscribers.size} Stdout subscribers"

        subscribers.each do |subscriber|
          subscriber.touch(:stdout_last_sent_at)

          Keygen.logger.info "Sending issue #11 to #{subscriber.email}"

          StdoutMailer.issue_eleven(subscriber:)
                      .deliver_later(
                        # Fan out deliveries
                        wait: rand(1.minute..8.hours),
                      )

          sleep 0.1
        end

        Keygen.logger.info "Done"
      end
    end
  end
end
