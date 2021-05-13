class AddPromptForReviewNotificationToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :last_prompt_for_review_sent_at, :datetime
  end
end
