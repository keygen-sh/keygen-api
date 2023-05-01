# frozen_string_literal: true

# NOTE(ezekg) This takes about an hour in multiplayer mode with a Ryzen 3700x
#             CPU, generating roughly 2GB of data. n = number of accounts.
i = 0
n = 10

loop do
  event_types = EventType.pluck(:id)

  Account.transaction do
    domain  = Faker::Internet.unique.domain_name
    account = Account.create!(
      users_attributes: Array.new(rand(1..5)) {{ email: Faker::Internet.unique.email(domain:), password: Faker::Internet.password }},
      billing_attributes: { state: %w[subscribed canceled].sample },
      plan_attributes: { name: %w[Ent Std Dev].sample, price: 1 },
      name: Faker::Company.name,
    )

    sandbox = Environment.create!(
      isolation_strategy: 'ISOLATED',
      name: 'Sandbox',
      code: 'sandbox',
      account:,
    )

    live = Environment.create!(
      isolation_strategy: 'SHARED',
      name: 'Live',
      code: 'live',
      account:,
    )

    [nil, *account.environments].each do |environment|
      rand(0..10).times do
        buzzword = Faker::Company.unique.buzzword

        Entitlement.create!(
          name: buzzword,
          code: buzzword.upcase,
          environment:,
          account:,
        )
      end

      rand(0..3).times do
        Product.create!(
          name: Faker::App.unique.name,
          environment:,
          account:,
        )
      end
    end

    # Distribution
    account.products.find_each do |product|
      environment = product.environment

      rand(0..20).times do
        release = Release.create!(
          channel_attributes: { key: 'stable' },
          version: Faker::App.unique.semantic_version,
          name: Faker::App.name,
          product:,
          account:,
        )

        rand(1..10).times do
          ext = %w[exe tar.gz zip dmg].sample
          artifact = ReleaseArtifact.create!(
            platform_attributes: { key: Faker::Computer.platform.downcase },
            arch_attributes: { key: %w[x86 386 amd64 arm arm64].sample },
            filetype_attributes: { key: ext },
            filename: Faker::File.unique.file_name(ext:),
            filesize: rand(1.gigabyte),
            release:,
            account:,
          )
        end
      end

      # Licensing
      rand(0..3).times do
        policy = Policy.create!(
          name: 'Floating Policy',
          authentication_strategy: %w[TOKEN LICENSE MIXED].sample,
          duration: [nil, 1.year, 1.month, 2.weeks].sample,
          max_machines: 5,
          floating: true,
          product:,
          account:,
        )

        rand(0..10_000).times do
          user = if rand(0..10).zero?
                   User.create!(
                     email: Faker::Internet.email(name: "#{Faker::Name.first_name} #{SecureRandom.hex(4)}"),
                     environment:,
                     account:,
                   )
                 end

          license = License.create!(
            name: 'Floating License',
            policy:,
            user:,
            account:,
          )

          rand(0..5).times do
            Machine.create!(
              fingerprint: SecureRandom.hex,
              license:,
              account:,
            )
          end
        end
      end
    end

    # Activity
    rand(0..100_000).times do
      request_time = rand(1.year).seconds.ago
      request_id   = SecureRandom.uuid

      resource    = account.licenses.sample
      environment = resource.environment
      requestor   = account.admins.for_environment(environment).sample || resource

      request_log = RequestLog.create!(
        id: request_id,
        created_date: request_time,
        created_at: request_time,
        updated_at: Time.current,
        user_agent: Faker::Internet.user_agent,
        method: %w[GET POST PUT PATCH DELETE].sample,
        url: '/',
        request_body: nil,
        ip: Faker::Internet.ip_v4_address,
        response_signature: SecureRandom.base64,
        response_body: '{"data":null,"errors":[],"meta":{"sample":true}}',
        status: %w[200 201 204 303 400 401 403 404 422],
        environment:,
        resource:,
        requestor:,
        account:,
      )

      event_log = EventLog.create!(
        event_type_id: event_types.sample,
        idempotency_key: SecureRandom.hex,
        whodunnit: requestor,
        environment:,
        resource:,
        request_log:,
        account:,
      )
    end
  rescue ActiveRecord::RecordNotSaved => e
    pp(errors: e.record.errors.full_messages)

    raise
  ensure
    Faker::UniqueGenerator.clear

    i += 1
  end

  break unless
    Keygen.multiplayer?

  break unless
    i < n
end
