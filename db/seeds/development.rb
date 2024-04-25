# frozen_string_literal: true

# NOTE(ezekg) This takes about an hour in multiplayer mode with a Ryzen 3700x
#             CPU, generating roughly 2GB of data when n = 10.
n = ENV.fetch('N') { 1 }.to_i
i = 0

loop do
  event_types = EventType.pluck(:id)

  begin
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
      if rand(0..1).zero? && environment.present?
        Token.create!(bearer: environment, account:, environment:)
      end

      rand(0..100).times do
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

    account.products.find_each do |product|
      environment = product.environment

      if rand(0..1).zero?
        Token.create!(bearer: product, account:, environment:)
      end

      # Distribution
      unless ENV.key?('SKIP_DISTRIBUTION')
        rand(0..3).times do
          name    = "#{product.name} #{Faker::Hacker.unique.noun.capitalize}"
          package = if rand(0..1).zero?
                      engine = if rand(0..1).zero?
                                { engine_attributes: { key: %w[pypi tauri].sample } }
                              else
                                {}
                              end

                      ReleasePackage.create!(
                        key: name.parameterize,
                        name: name,
                        environment:,
                        product:,
                        account:,
                        **engine,
                      )
                    end

          rand(0..20).times do
            version = Faker::App.unique.semantic_version
            release = Release.create!(
              channel_attributes: { key: 'stable' },
              name: "#{name} v#{version}",
              version:,
              environment:,
              package:,
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
                environment:,
                release:,
                account:,
              )
            end
          end
        end
      end

      # Licensing
      unless ENV.key?('SKIP_LICENSING')
        rand(1..3).times do
          policy = Policy.create!(
            name: 'Floating Policy',
            authentication_strategy: %w[TOKEN LICENSE MIXED].sample,
            duration: [nil, 1.year, 1.month, 2.weeks].sample,
            max_machines: nil,
            floating: true,
            environment:,
            product:,
            account:,
          )

          if rand(0..3).zero?
            account.entitlements.for_environment(environment, strict: true).find_each do |entitlement|
              unless rand(0..5).zero?
                PolicyEntitlement.create!(
                  environment:,
                  account:,
                  entitlement:,
                  policy:,
                )
              end
            end
          end

          rand(1..10_000).times do
            owner = if rand(0..5).zero?
                      User.create!(
                        email: Faker::Internet.email(name: "#{Faker::Name.first_name} #{SecureRandom.hex(4)}"),
                        environment:,
                        account:,
                      )
                    end

            license = License.create!(
              name: 'Floating License',
              environment:,
              policy:,
              account:,
              owner:,
            )

            if rand(0..10).zero?
              Token.create!(bearer: license, account:, environment:)
            end

            if rand(0..3).zero?
              LicenseEntitlement.create!(
                entitlement: account.entitlements.for_environment(environment, strict: true)
                                                 .excluding(*policy.entitlements)
                                                 .to_a.sample,
                environment:,
                account:,
                license:,
              )
            end

            if rand(0..5).zero?
              rand(0..10).times do
                user = if rand(0..3).zero?
                        User.create!(
                          email: Faker::Internet.email(name: "#{Faker::Name.first_name} #{SecureRandom.hex(4)}"),
                          environment:,
                          account:,
                        )
                      else
                        User.where.not(id: owner) # filter out the owner otherwise it'll raise
                            .reorder(:id) # sorting on UUID is effectively random if inserts are constant
                            .offset((rand() * account.users.for_environment(environment, strict: true).count).floor) # random user
                            .limit(1)
                            .find_by(
                              environment:,
                              account:,
                            )
                      end

                if rand(0..1).zero? && user.present?
                  Token.create!(bearer: user, account:, environment:)
                end

                LicenseUser.create!(
                  environment:,
                  account:,
                  license:,
                  user:,
                )
              rescue ActiveRecord::RecordInvalid
                # ignore duplicates
              end
            end

            rand(0..license.users.count).times do
              owner = if rand(0..5).zero?
                        license.users.reorder(:id) # sorting on UUID is effectively random if inserts are constant
                                     .offset((rand() * license.users.count).floor) # random user
                                     .limit(1)
                                     .find_by(
                                       environment:,
                                       account:,
                                     )
                      end

              machine = Machine.create!(
                fingerprint: SecureRandom.hex,
                environment:,
                license:,
                account:,
                owner:,
              )

              if rand(0..5).zero?
                names = %w[
                  MOBO
                  GPU
                  CPU
                  MAC
                  HDD
                  SSD
                  RAM
                ]

                names.each do |name|
                  next if rand(0..1).zero?

                  MachineComponent.create!(
                    fingerprint: SecureRandom.hex,
                    environment:,
                    account:,
                    machine:,
                    name:,
                  )
                end
              end
            end
          end
        end
      end
    end

    # Activity
    unless ENV.key?('SKIP_ACTIVITY')
      routes = Rails.application.routes.routes.select { _1.requirements[:subdomain] == 'api' }

      rand(0..100_000).times do
        request_time = rand(1.year).seconds.ago
        request_id   = SecureRandom.uuid

        # Select a random route
        route  = routes.sample
        method = route.verb
        url    = route.format(
          route.required_parts.reduce({}) { _1.merge(_2 => SecureRandom.uuid) },
        )

        resource    = route.requirements[:controller].classify.split('::').last.safe_constantize
        environment = resource.try(:environment)
        admins      = account.admins.for_environment(environment, strict: true).sample
        requestor   = if resource.respond_to?(:role) && rand(0..1).zero?
                        resource
                      else
                        admin
                      end

        request_log = RequestLog.create!(
          id: request_id,
          created_date: request_time,
          created_at: request_time,
          updated_at: Time.current,
          user_agent: Faker::Internet.user_agent,
          ip: Faker::Internet.ip_v4_address,
          request_body: method.in?(%w[POST PUT PATCH]) ? '{"data":null,"meta":{"sample":true}}' : nil,
          response_signature: SecureRandom.base64,
          response_body: '{"data":null,"errors":[],"meta":{"sample":true}}',
          status: %w[200 201 204 303 302 307 400 401 403 404 422],
          method:,
          url:,
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
