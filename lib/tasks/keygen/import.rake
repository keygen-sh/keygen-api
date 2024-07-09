# frozen_string_literal: true

namespace :keygen do
  desc 'Import data into a Keygen account'
  task :import, %i[account_id secret_key] => %i[silence environment] do |_, args|
    def getn(n) = STDIN.read(n)

    ActiveRecord::Base.logger.silence do
      account_id = args[:account_id] || ENV.fetch('KEYGEN_ACCOUNT_ID')
      secret_key = args[:secret_key]

      account = Account.find(account_id)
      version = getn(1).unpack1('C')

      puts(version:)

      while chunk_prefix = getn(8)
        chunk_size = chunk_prefix.unpack1('Q>')
        chunk      = getn(chunk_size)
        packed     = Zlib.inflate(chunk)
        unpacked   = MessagePack.unpack(packed)

        # TODO(ezekg) import into db
        class_name, attributes = unpacked

        puts(class_name => attributes)
      end
    end
  end
end
