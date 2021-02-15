# heroku run -e BATCH_SIZE=10000 rails runner db/scripts/prune_metrics.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
batch = 0

puts "[scripts.prune_metrics] Starting"

loop do
  count = Metric.where('created_at < ?', 90.days.ago).limit(BATCH_SIZE).delete_all
  batch += 1

  puts "[scripts.prune_metrics] Pruned #{count} metric rows (batch ##{batch})"

  break if count == 0
end

puts "[scripts.prune_metrics] Done"