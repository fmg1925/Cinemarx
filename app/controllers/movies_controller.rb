# app/controllers/movies_controller.rb
class MoviesController < ApplicationController
  API_KEY = ENV["API_KEY"]
  AUTH_TOKEN = ENV["TOKEN"]

  def index
    page = params[:page] || 1

    language = current_language_code

    api_url = "https://api.themoviedb.org/3/movie/popular?api_key=#{API_KEY}&language=#{language}&page=#{page}"
    response = HTTParty.get(api_url, headers: { "Authorization" => "Bearer #{AUTH_TOKEN}" })

    if response.success?
      @movies = response.parsed_response["results"]
      @movies.each do |movie|
        tmdb_rating_5 = movie["vote_average"].to_f / 2.0
        tmdb_votes = movie["vote_count"].to_i rescue 0

        user_ratings = Rating.where(movie_id: movie["id"])
        user_avg = user_ratings.average(:score) || 0
        user_count = user_ratings.count

        total_votes = tmdb_votes + user_count

        if total_votes > 0
          combined = ((tmdb_rating_5 * tmdb_votes) + (user_avg * user_count)) / total_votes
        else
          combined = tmdb_rating_5
        end

        movie["rating"] = combined.round(2)
        movie["total_votes"] = total_votes
      end
      @total_pages = response.parsed_response["total_pages"]
      @current_page = page.to_i
    else
      @movies = []
      @total_pages = 1
      @current_page = 1
    end
  end

  def search
    query = params[:query]
    page = params[:page] || 1
    @current_page = page.to_i
    @total_pages = 0
    return @movies = [] if query.blank?

    I18n.locale = params[:locale] || extract_locale_from_referer || :en
    language = current_language_code

    api_url = "https://api.themoviedb.org/3/search/movie?api_key=#{API_KEY}&query=#{query}&language=#{language}&page=#{page}"

    response = HTTParty.get(api_url, headers: { "Authorization" => "Bearer #{AUTH_TOKEN}" })

    if response.success?
       @movies = response.parsed_response["results"]
        @movies.each do |movie|
          tmdb_rating_5 = movie["vote_average"].to_f / 2.0
          tmdb_votes = movie["vote_count"].to_i rescue 0

          user_ratings = Rating.where(movie_id: movie["id"])
          user_avg = user_ratings.average(:score) || 0
          user_count = user_ratings.count

          total_votes = tmdb_votes + user_count

          if total_votes > 0
            combined = ((tmdb_rating_5 * tmdb_votes) + (user_avg * user_count)) / total_votes
          else
            combined = tmdb_rating_5
          end

          movie["rating"] = combined.round(2)
          movie["total_votes"] = total_votes

          cache_movie_data(movie, current_language_code)
        end
      @total_pages = response.parsed_response["total_pages"]
      @current_page = page.to_i
    else
      @movies = []
      @total_pages = 0
      @current_page = 0
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

  def details
    unless session[:movie]
      redirect_to movies_path, alert: "Selecciona una película primero." and return
    end

    @movie = session[:movie]
    movie_id = @movie["id"]

    if logged_in?
      current_user.watched_movies.find_or_create_by(movie_id: movie_id)
    end

    cache_movie_data(@movie, current_language_code)
    CacheMovieJob.perform_later(movie_id, API_KEY, AUTH_TOKEN)
  end

  def store
    movie_data = params.require(:movie).permit(:id, :title, :overview, :poster_path, :vote_average, :vote_count, :rating, :total_votes).to_h
    session[:movie] = movie_data
    redirect_to details_movies_path
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
