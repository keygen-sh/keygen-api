# frozen_string_literal: true

namespace :keygen do
  desc 'Import data into a Keygen account'
  task :import, %i[account_id] => %i[silence environment] do |_, args|
    def getn(n) = STDIN.read(n)

    ActiveRecord::Base.logger.silence do
      account_id = args[:account_id] || ENV.fetch('KEYGEN_ACCOUNT_ID')
      account    = Account.find(account_id)

      while prefix = getn(4)
        bytesize   = prefix.unpack1('L>')
        compressed = getn(bytesize)
        packed     = Zlib.inflate(compressed)
        unpacked   = MessagePack.unpack(packed)

        # TODO(ezekg) import into db
        puts(unpacked)
      end
    end
  end
end
