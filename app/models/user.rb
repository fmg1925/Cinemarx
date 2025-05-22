class User < ApplicationRecord
  has_secure_password

  has_many :ratings
  has_many :watched_movies
  has_many :favorite_movies

  validates :username, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 8 }, allow_nil: true
end
