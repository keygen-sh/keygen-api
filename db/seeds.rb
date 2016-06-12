# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Plan.create!({
  name: "Weekender",
  price: 0,
  max_products: 1,
  max_users: 250,
  max_licenses: 250,
  max_policies: 1
})

Plan.create!({
  name: "Startup",
  price: 2400,
  max_products: 5,
  max_users: 1000,
  max_licenses: 5000,
  max_policies: 5
})

Plan.create!({
  name: "Business",
  price: 4900,
  max_products: 25,
  max_users: 5000,
  max_licenses: 25000,
  max_policies: 25
})

account = Account.create!({
  name: "Apptacular",
  subdomain: "apptacular",
  plan: Plan.first,
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
  product: product
})

user = account.users.create!({
  name: "User",
  email: "user@keygin.io",
  password: "password",
  products: [product]
})

account.licenses.create!({
  key: SecureRandom.hex,
  user: user,
  policy: policy
})
