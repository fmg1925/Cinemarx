class HomeController < ApplicationController
  def index
    return unless logged_in?

    page = params[:page].to_i
    page = 1 if page < 1
    per_page = 10

    I18n.locale = params[:locale] || extract_locale_from_referer || :en
    language = current_language_code

    favorites = current_user.favorite_movies.order(created_at: :desc)
    user_ratings = current_user.ratings.order(created_at: :desc)
    watched = current_user.watched_movies.order(created_at: :desc)

    favorite_ids = favorites.pluck(:movie_id)
    rating_ids = user_ratings.pluck(:movie_id)

    favoritemovies = favorites.map do |favoritemovie|
      cached = CachedMovie.find_by(movie_id: favoritemovie.movie_id, language: language)
      next unless cached

      tmdb_rating_5 = cached.vote_average.to_f / 2.0
      tmdb_votes = cached.vote_count.to_i rescue 0

      user_avg = Rating.where(movie_id: favoritemovie.movie_id).average(:score) || 0
      user_count = Rating.where(movie_id: favoritemovie.movie_id).count
      rating = Rating.find_by(user_id: current_user.id, movie_id: favoritemovie.movie_id)
      total_votes = tmdb_votes + user_count

      combined = total_votes > 0 ? ((tmdb_rating_5 * tmdb_votes + user_avg * user_count) / total_votes) : tmdb_rating_5
      {
        "id" => favoritemovie.movie_id,
        "title" => cached.title,
        "overview" => cached.overview,
        "poster_path" => cached.poster_path,
        "user_score" => rating&.score || nil,
        "rating" => combined.round(2),
        "total_votes" => total_votes
      }
    end.compact

    all_rated = user_ratings.reject { |rating| favorite_ids.include?(rating.movie_id) }.map do |rating|
      movie_id = rating.movie_id

      cached = CachedMovie.find_by(movie_id: movie_id, language: language)
      next unless cached
      tmdb_rating_5 = cached.vote_average.to_f / 2.0
      tmdb_votes = cached.vote_count.to_i rescue 0

      user_avg = Rating.where(movie_id: movie_id).average(:score) || 0
      user_count = Rating.where(movie_id: movie_id).count
      total_votes = tmdb_votes + user_count

      combined = total_votes > 0 ? ((tmdb_rating_5 * tmdb_votes + user_avg * user_count) / total_votes) : tmdb_rating_5

      {
        "id" => movie_id,
        "title" => cached.title,
        "overview" => cached.overview,
        "poster_path" => cached.poster_path,
        "user_score" => rating.score,
        "rating" => combined.round(2),
        "total_votes" => total_votes
      }
    end.compact

    watchedmovies = watched.reject { |watchedmovie| rating_ids.include?(watchedmovie.movie_id) }.map do |watchedmovie|
      cached = CachedMovie.find_by(movie_id: watchedmovie.movie_id, language: language)
      next unless cached

      tmdb_rating_5 = cached.vote_average.to_f / 2.0
      tmdb_votes = cached.vote_count.to_i rescue 0

      user_avg = Rating.where(movie_id: watchedmovie.movie_id).average(:score) || 0
      user_count = Rating.where(movie_id: watchedmovie.movie_id).count
      total_votes = tmdb_votes + user_count

      combined = total_votes > 0 ? ((tmdb_rating_5 * tmdb_votes + user_avg * user_count) / total_votes) : tmdb_rating_5

      {
        "id" => watchedmovie.movie_id,
        "title" => cached.title,
        "overview" => cached.overview,
        "poster_path" => cached.poster_path,
        "rating" => combined.round(2),
        "total_votes" => total_votes
      }
    end.compact

    @favorite_movies = favoritemovies[((page - 1) * per_page), per_page] || []
    @rated_movies = all_rated[((page - 1) * per_page), per_page] || []
    @watched_movies = watchedmovies[((page - 1) * per_page), per_page] || []

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("favorite_movies", partial: "home/favorite_movies", locals: { favorite_movies: @favorite_movies }),
          turbo_stream.replace("rated_movies", partial: "home/rated_movies", locals: { rated_movies: @rated_movies }),
          turbo_stream.replace("watched_movies", partial: "home/watched_movies", locals: { watched_movies: @watched_movies })
        ]
      end
    end
  end

  def extract_locale_from_referer
  URI.parse(request.referer || "").query
    &.split("&")
    &.map { |p| p.split("=") }
    &.to_h["locale"]
    &.to_sym
  rescue
    nil
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
