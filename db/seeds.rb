# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Plan.create!([{
  plan_id: "weekender",
  name: "Weekender",
  price: 900,
  max_products: 1,
  max_users: 250,
  max_licenses: 250,
  max_policies: 1
}, {
  plan_id: "startup",
  name: "Startup",
  price: 2400,
  max_products: 5,
  max_users: 1000,
  max_licenses: 5000,
  max_policies: 5
}, {
  plan_id: "business",
  name: "Business",
  price: 4900,
  max_products: 25,
  max_users: 5000,
  max_licenses: 25000,
  max_policies: 25
}])

account = Account.create!(
  name: "Apptacular",
  subdomain: "apptacular",
  plan: Plan.first,
  users_attributes: [{
    name: "Admin",
    email: "admin@keygen.sh",
    password: "password"
  }]
)

account.webhook_endpoints.create!(
  url: "https://keygen.sh"
)

product = account.products.create!(
  name: "Apptastic"
)

policy = account.policies.create!(
  name: "Premium Add-On",
  price: 199,
  product: product,
  max_machines: 5,
  floating: true,
  duration: 2.weeks
)

enc_policy = account.policies.create!(
  name: "Secret Add-On",
  price: 999,
  product: product,
  max_machines: 5,
  floating: true,
  encrypted: true,
  duration: 1.month
)

account.keys.create!(
  key: SecureRandom.hex.scan(/.{4}/).join("-"),
  policy: policy
)
account.keys.create!(
  key: SecureRandom.hex.scan(/.{4}/).join("-"),
  policy: policy
)
account.keys.create!(
  key: SecureRandom.hex.scan(/.{4}/).join("-"),
  policy: policy
)

user = account.users.create!(
  name: "User",
  email: "user@keygen.sh",
  password: "password"
)

license = account.licenses.create!(
  policy: policy,
  user: user
)

enc_license = account.licenses.create!(
  policy: enc_policy,
  user: user
)

account.machines.create!(
  fingerprint: SecureRandom.hex.scan(/.{2}/).join(":"),
  license: license
)
account.machines.create!(
  fingerprint: SecureRandom.hex.scan(/.{2}/).join(":"),
  license: license
)
account.machines.create!(
  fingerprint: SecureRandom.hex.scan(/.{2}/).join(":"),
  license: enc_license
)
