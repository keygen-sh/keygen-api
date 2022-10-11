# frozen_string_literal: true

desc 'send a stdout issue'
namespace :stdout do
  namespace :send do
    task zero: [:environment] do
      raise NotImplementedError, 'Stdout issue #0 has already been sent'
    end

    task one: [:environment] do
      raise NotImplementedError, 'Stdout issue #1 has already been sent'
    end

    task two: [:environment] do
      raise NotImplementedError, 'Stdout issue #2 has already been sent'
    end

    task three: [:environment] do
      subscribers = User.stdout_subscribers(with_activity_from: 1.year.ago)
                        .where('stdout_last_sent_at is null or stdout_last_sent_at < ?', 7.days.ago)
                        .select(:id, :email, :first_name)
                        .reorder(:email, :created_at)
                        .to_a

      Keygen.logger.info "Sending second issue to #{subscribers.size} Stdout subscribers"

      subscribers.each do |subscriber|
        subscriber.touch(:stdout_last_sent_at)

        Keygen.logger.info "Sending issue #2 to #{subscriber.email}"

        StdoutMailer.issue_three(subscriber: subscriber)
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
