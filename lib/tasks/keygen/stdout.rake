# frozen_string_literal: true

namespace :keygen do
  desc 'Send an issue of Stdout'
  namespace :stdout do
    namespace :send do
      task zero: %i[environment] do
        raise NotImplementedError, 'Stdout issue #0 has already been sent'
      end

      task one: %i[environment] do
        raise NotImplementedError, 'Stdout issue #1 has already been sent'
      end

      task two: %i[environment] do
        raise NotImplementedError, 'Stdout issue #2 has already been sent'
      end

      task three: %i[environment] do
        raise NotImplementedError, 'Stdout issue #3 has already been sent'
      end

      task four: %i[environment] do
        subscribers = User.stdout_subscribers(with_activity_from: 7.years.ago)
                          .where('stdout_last_sent_at is null or stdout_last_sent_at < ?', 7.days.ago)
                          .select(:id, :email, :first_name)
                          .reorder(:email, :created_at)
                          .to_a

        Keygen.logger.info "Sending issue #4 to #{subscribers.size} Stdout subscribers"

        subscribers.each do |subscriber|
          subscriber.touch(:stdout_last_sent_at)

          Keygen.logger.info "Sending issue #4 to #{subscriber.email}"

          StdoutMailer.issue_four(subscriber:)
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
end
