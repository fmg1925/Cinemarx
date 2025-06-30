# frozen_string_literal: true

class FavoriteMovie < ApplicationRecord
  belongs_to :user

  validates :movie_id, presence: true
  validates :user_id, presence: true
  validates :movie_id, uniqueness: { scope: :user_id }
end
