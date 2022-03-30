page_dir    = 'DESC'
page_model  = License.reorder("created_at #{page_dir}")
page_cursor = page_model.first.id
page_size   = 3
page_num    = 0

loop do
  page_num += 1
  page      = page_model.where.not(id: page_cursor)
                        .where(
                          page_dir == 'DESC' ? 'created_at <= (?)' : 'created_at >= (?)',
                          page_model.where(id: page_cursor).select(:created_at).limit(1)
                        )
                        .limit(page_size)

  puts "Found #{page.length} records: dir=#{page_dir} page=#{page_num} cursor=#{page_cursor}"
  puts "  IDs: #{page.map(&:id)}"

  break if
    page.length != page_size

  page_cursor = page.last.id
end
