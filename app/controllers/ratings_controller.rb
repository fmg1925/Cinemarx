class RatingsController < ApplicationController
  before_action :require_login

  API_KEY = ENV["API_KEY"]
  AUTH_TOKEN = ENV["TOKEN"]

  def create
    rating = Rating.find_or_initialize_by(user_id: current_user.id, movie_id: params[:rating][:movie_id])
    rating.score = params[:rating][:score]
    movie = params[:movie]

    if rating.save
      ratings = Rating.where(movie_id: rating.movie_id).average(:score)
      count = Rating.where(movie_id: rating.movie_id).count.to_f

      cache_movie_data(movie, current_language_code)

      CacheMovieJob.perform_later(rating.movie_id, API_KEY, AUTH_TOKEN)

      render json: {
        ratings: ratings,
        count: count.to_i
      }
    else
      render json: { errors: rating.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def cache_movie_data(movie, language)
    CachedMovie.upsert(
      {
        movie_id: movie["id"],
        language: language,
        title: movie["title"],
        overview: movie["overview"],
        poster_path: movie["poster_path"],
        vote_average: movie["vote_average"],
        vote_count: movie["vote_count"],
        updated_at: Time.current
      },
      unique_by: %i[movie_id language]
    )
  end

  private

  def current_language_code
    case I18n.locale
    when :es then "es-MX"
    when :en then "en-US"
    when :ko then "ko-KR"
    when :zh then "zh-CN"
    else "en-US"
    end
  end
end
