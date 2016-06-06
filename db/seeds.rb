# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Plan.create([
#   {
#     name: "Weekender",
#     pitch: "Generous limits for hobbyists",
#     price: 0,
#     max_products: 1,
#     max_users: 250,
#     max_licenses: 250,
#     max_policies: 1
#   },
#   {
#     name: "Startup",
#     pitch: "Affordable pricing for growing apps",
#     price: 2400,
#     max_products: 5,
#     max_users: 1000,
#     max_licenses: 5000,
#     max_policies: 5
#   },
#   {
#     name: "Business",
#     pitch: "Predictable pricing for apps at scale",
#     price: 4900,
#     max_products: 25,
#     max_users: 5000,
#     max_licenses: 25000,
#     max_policies: 25
#   }
# ])

Account.create({
  name: "Keygin",
  subdomain: "keygin"
})

Account.first.products.create([
  {
    name: "App 1"
  },
  {
    name: "App 2"
  }
])

Account.first.products.first.policies.create({
  name: "Premium Add-On",
  price: 199
})

Account.first.products.first.policies.first.licenses.create({
  key: SecureRandom.hex
})

Account.first.users.create({
  name: "User",
  email: "user@keygin.io",
  password: "password",
  products: [Account.first.products.first]
})
