# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Plan.create!([{
  name: "Weekender",
  external_plan_id: "weekender",
  price: 900,
  max_products: 1,
  max_users: 250,
  max_licenses: 250,
  max_policies: 1
}, {
  name: "Startup",
  external_plan_id: "startup",
  price: 2400,
  max_products: 5,
  max_users: 1000,
  max_licenses: 5000,
  max_policies: 5
}, {
  name: "Business",
  external_plan_id: "business",
  price: 4900,
  max_products: 25,
  max_users: 5000,
  max_licenses: 25000,
  max_policies: 25
}])

billing = Billing.create!({
  external_customer_id: "cust_id",
  external_subscription_status: "active"
})

account = Account.create!({
  name: "Apptacular",
  subdomain: "apptacular",
  plan: Plan.first,
  billing: billing,
  users_attributes: [{
    name: "Admin",
    email: "admin@keygin.io",
    password: "password"
  }]
})

product = account.products.create!({
  name: "Apptastic"
})

policy = account.policies.create!({
  name: "Premium Add-On",
  price: 199,
  product: product,
  max_machines: 5,
  floating: true,
  duration: 2.weeks
})

account.keys.create!({
  key: SecureRandom.hex.scan(/.{4}/).join("-"),
  policy: policy
})
account.keys.create!({
  key: SecureRandom.hex.scan(/.{4}/).join("-"),
  policy: policy
})
account.keys.create!({
  key: SecureRandom.hex.scan(/.{4}/).join("-"),
  policy: policy
})

user = account.users.create!({
  name: "User",
  email: "user@keygin.io",
  password: "password",
  products: [product]
})

license = account.licenses.create!({
  key: SecureRandom.hex,
  user: user,
  policy: policy
})

account.machines.create!({
  fingerprint: SecureRandom.hex.scan(/.{2}/).join("-"),
  license: license
})
account.machines.create!({
  fingerprint: SecureRandom.hex.scan(/.{2}/).join("-"),
  license: license
})
account.machines.create!({
  fingerprint: SecureRandom.hex.scan(/.{2}/).join("-"),
  license: license
})
