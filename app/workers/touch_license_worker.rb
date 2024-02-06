# frozen_string_literal: true

class TouchLicenseWorker < BaseWorker
  sidekiq_options retry: false,
    lock: :until_executing,
    on_conflict: {
      client: :replace,
      server: :raise,
    }

  def perform(license_id, touches)
    license = License.find(license_id)

    # We're going to attempt to update the license's last validated timestamp and
    # other metadata, but if there's a concurrent update then we'll skip. This
    # sheds load when a license is validated too often, e.g. in an infinite
    # loop or via a high number of concurrent processes.
    license.with_lock 'FOR UPDATE SKIP LOCKED' do
      license.update!(**touches.symbolize_keys)
    end
  rescue ActiveRecord::LockWaitTimeout, # For NOWAIT lock wait timeout error
         ActiveRecord::RecordNotFound   # SKIP LOCKED also raises not found
    # noop
  end
end
