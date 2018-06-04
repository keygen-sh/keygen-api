# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
Plan.create([{
  plan_id: "weekender",
  name: "Weekender",
  price: 9_00,
  max_products: 1,
  max_users: 250,
  max_licenses: 250,
  max_policies: 1
}, {
  plan_id: "startup",
  name: "Startup",
  price: 24_00,
  max_products: 5,
  max_users: 1000,
  max_licenses: 5000,
  max_policies: 5
}, {
  plan_id: "business",
  name: "Business",
  price: 49_00,
  max_products: 25,
  max_users: 5_000,
  max_licenses: 25_000,
  max_policies: 25
}])

5.times do
  account = Account.create(
    name: "Account",
    slug: SecureRandom.hex,
    plan: Plan.all.sample,
    users_attributes: [{
      first_name: "Admin",
      last_name: "Admin",
      email: "admin@keygen.sh",
      password: "password"
    }]
  )

  account.webhook_endpoints.create(
    url: "https://keygen.sh"
  )

  product = account.products.create(
    name: "App"
  )

  policy = account.policies.create(
    name: "Premium Add-On",
    product: product,
    floating: true,
    duration: 2.weeks
  )
  pool_policy = account.policies.create(
    name: "Premium Add-On",
    product: product,
    use_pool: true,
    duration: 4.weeks
  )
  enc_policy = account.policies.create(
    name: "Secret Add-On",
    product: product,
    floating: true,
    encrypted: true,
    duration: 1.month
  )

  5_000.times do
    account.keys.create(
      key: SecureRandom.hex.scan(/.{4}/).join("-"),
      policy: pool_policy
    )
    account.keys.create(
      key: SecureRandom.hex.scan(/.{4}/).join("-"),
      policy: pool_policy
    )
    account.keys.create(
      key: SecureRandom.hex.scan(/.{4}/).join("-"),
      policy: pool_policy
    )

    user = account.users.create(
      first_name: "#{SecureRandom.hex}",
      last_name: "#{SecureRandom.hex}",
      email: "#{SecureRandom.hex}@keygen.sh",
      password: "password"
    )

    license = account.licenses.create(
      policy: policy,
      user: user
    )
    pool_license = account.licenses.create(
      policy: pool_policy,
      user: user
    )
    enc_license = account.licenses.create(
      policy: enc_policy,
      user: user
    )

    account.machines.create(
      fingerprint: SecureRandom.hex.scan(/.{2}/).join(":"),
      license: license
    )
    account.machines.create(
      fingerprint: SecureRandom.hex.scan(/.{2}/).join(":"),
      license: pool_license
    )
    account.machines.create(
      fingerprint: SecureRandom.hex.scan(/.{2}/).join(":"),
      license: enc_license
    )
  end

  User.find_each do |user|
    token = user.tokens.create account: user.account
    token.generate!
  end
end
