# frozen_string_literal: true

class Rating < ApplicationRecord
  belongs_to :user

  validates :movie_id, presence: true
  validates :score, inclusion: { in: 1..5 }
  validates :movie_id, uniqueness: { scope: :user_id, message: 'ya fue calificada por este usuario' }
end
