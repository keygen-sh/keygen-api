# heroku run -e BATCH_SIZE=10000 rails runner db/scripts/prune_request_logs.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
batch = 0

puts "[scripts.prune_request_logs] Starting"

Account.find_each do |account|
  puts "[scripts.prune_request_logs] Pruning requests logs for account #{account.id}"

  loop do
    count = account.request_logs.where('created_at < ?', 90.days.ago).limit(BATCH_SIZE).delete_all
    batch += 1

    puts "[scripts.prune_request_logs] Pruned #{count} request log rows (batch ##{batch})"

    break if count == 0
  end
end

puts "[scripts.prune_request_logs] Done"