class FavoritesController < ApplicationController
  before_action :require_login

  API_KEY = ENV["API_KEY"]
  AUTH_TOKEN = ENV["TOKEN"]

  def create
    favorite = FavoriteMovie.find_by(user_id: current_user.id, movie_id: params[:movie_id])

    if favorite
      favorite.destroy
      render json: { success: true }
    else
      new_favorite = FavoriteMovie.new(user_id: current_user.id, movie_id: params[:movie_id])
      if new_favorite.save
        movie = params[:movie]
        cache_movie_data(movie, current_language_code)

        CacheMovieJob.perform_later(params[:movie_id], API_KEY, AUTH_TOKEN)

        render json: { success: true }
      else
        render json: { errors: favorite.errors.full_messages }, status: :unprocessable_entity
      end
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
