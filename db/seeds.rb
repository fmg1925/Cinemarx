# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require 'faker'

usernames = []

10.times do
  username = Faker::Internet.unique.username
  usernames << username

  User.create!(
    username: username,
    password: "password",
    password_confirmation: "password"
  )
end

User.create!(username: "admin", password: "secret12", password_confirmation: "secret12", admin: true)

puts "Created 10 users with Faker!"
