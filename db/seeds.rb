# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Plan.new({
    name: "Weekender",
    # pitch: "Generous limits for hobbyists",
    price: 0,
    max_products: 1,
    max_users: 250,
    max_licenses: 250,
    max_policies: 1
}).save!

Plan.new({
  name: "Startup",
  # pitch: "Affordable pricing for growing apps",
  price: 2400,
  max_products: 5,
  max_users: 1000,
  max_licenses: 5000,
  max_policies: 5
}).save!

Plan.new({
  name: "Business",
  # pitch: "Predictable pricing for apps at scale",
  price: 4900,
  max_products: 25,
  max_users: 5000,
  max_licenses: 25000,
  max_policies: 25
}).save!

Account.new({
  name: "Keygin",
  subdomain: "keygin"
}).save!

Account.first.products.new({
  name: "App 1"
}).save!

Account.first.products.new({
  name: "App 2"
}).save!

Account.first.products.first.policies.new({
  name: "Premium Add-On",
  price: 199
}).save!

Account.first.users.new({
  name: "User",
  email: "user@keygin.io",
  password: "password",
  products: [Account.first.products.first]
}).save!

Account.first.policies.first.licenses.new({
  key: SecureRandom.hex,
  user: Account.first.users.first,
  policy: Account.first.products.first.policies.first
}).save!
