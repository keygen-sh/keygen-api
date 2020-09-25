# heroku run -e BATCH_SIZE=10000 rails runner db/scripts/prune_webhook_events.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
batch = 0

puts "[scripts.prune_webhook_events] Starting"

loop do
  count = WebhookEvent.where('created_at < ?', 1.year.ago).limit(BATCH_SIZE).delete_all
  batch += 1

  puts "[scripts.prune_webhook_events] Pruned #{count} webhook event rows (batch ##{batch})"

  break if count == 0
end

puts "[scripts.prune_webhook_events] Done"