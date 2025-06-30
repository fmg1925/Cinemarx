# frozen_string_literal: true

# app/controllers/movies_controller.rb
class MoviesController < ApplicationController
  require 'erb'
  API_KEY = ENV['API_KEY']
  AUTH_TOKEN = ENV['TOKEN']

  def index
    page = [params[:page].to_i, 1].max
    page = 500 if page > 500
    max_pages = 500

    language = current_language_code

    api_url = "https://api.themoviedb.org/3/movie/popular?api_key=#{API_KEY}&language=#{language}&page=#{page}"
    response = HTTParty.get(api_url, headers: { 'Authorization' => "Bearer #{AUTH_TOKEN}" })

    if response.success?
      rawmovies = response.parsed_response['results']
      total_results = response.parsed_response['total_results']
      total_results = [total_results, max_pages * 20].min

      rawmovies.each do |movie|
        tmdb_rating_5 = movie['vote_average'].to_f / 2.0
        tmdb_votes = begin
          movie['vote_count'].to_i
        rescue StandardError
          0
        end

        user_ratings = Rating.where(movie_id: movie['id'])
        user_avg = user_ratings.average(:score) || 0
        user_count = user_ratings.count

        total_votes = tmdb_votes + user_count

        combined = if total_votes.positive?
                     ((tmdb_rating_5 * tmdb_votes) + (user_avg * user_count)) / total_votes
                   else
                     tmdb_rating_5
                   end

        movie['rating'] = combined.round(2)
        movie['total_votes'] = total_votes
      end
      @movies = Kaminari.paginate_array(rawmovies, total_count: total_results).page(page).per(20)
      @total_pages = response.parsed_response['total_pages']
    else
      @movies = Kaminari.paginate_array([]).page(page).per(20)
    end
  end

  def search
    query = params[:query]
    page = [params[:page].to_i, 1].max
    page = 500 if page > 500
    max_pages = 500
    return @movies = Kaminari.paginate_array([]).page(page).per(20) if query.blank?

    I18n.locale = params[:locale] || extract_locale_from_referer || :en
    language = current_language_code

    encoded_query = ERB::Util.url_encode(query)
    api_url = "https://api.themoviedb.org/3/search/movie?api_key=#{API_KEY}&query=#{encoded_query}&language=#{language}&page=#{page}"

    response = HTTParty.get(api_url, headers: { 'Authorization' => "Bearer #{AUTH_TOKEN}" })

    if response.success?
      raw_movies = response.parsed_response['results']
      total_results = response.parsed_response['total_results']
      total_results = [total_results, max_pages * 20].min

      raw_movies.each do |movie|
        tmdb_rating_5 = movie['vote_average'].to_f / 2.0
        tmdb_votes = begin
          movie['vote_count'].to_i
        rescue StandardError
          0
        end

        user_ratings = Rating.where(movie_id: movie['id'])
        user_avg = user_ratings.average(:score) || 0
        user_count = user_ratings.count

        total_votes = tmdb_votes + user_count

        combined = if total_votes.positive?
                     ((tmdb_rating_5 * tmdb_votes) + (user_avg * user_count)) / total_votes
                   else
                     tmdb_rating_5
                   end

        movie['rating'] = combined.round(2)
        movie['total_votes'] = total_votes

        cache_movie_data(movie, current_language_code)
      end
      @movies = Kaminari.paginate_array(raw_movies, total_count: total_results).page(page).per(20)
    else
      @movies = Kaminari.paginate_array([]).page(page).per(20)
    end
  end

  def extract_locale_from_referer
    URI.parse(request.referer || '').query
       &.split('&')
       &.map { |p| p.split('=') }
       &.to_h&.[]('locale')
       &.to_sym
  rescue StandardError
    nil
  end

  def details
    redirect_to movies_path, alert: 'Selecciona una película primero.' and return unless session[:movie]

    movie_session = session[:movie]
    movie_id = movie_session['id']
    language = current_language_code

    cached = CachedMovie.find_by(movie_id: movie_id, language: language)
    @comments = Comment.where(movie_id: movie_id).includes(:user).order(created_at: :desc)

    if cached
      @movie = movie_session.merge(
        'title' => cached.title,
        'overview' => cached.overview,
        'poster_path' => cached.poster_path,
        'backdrop_path' => cached.backdrop_path,
        'vote_average' => cached.vote_average.to_f,
        'vote_count' => cached.vote_count.to_i
      )
    else
      movie_url = "https://api.themoviedb.org/3/movie/#{movie_id}?language=#{current_language_code}&api_key=#{API_KEY}"
      response = HTTParty.get(movie_url, headers: { 'Authorization' => "Bearer #{AUTH_TOKEN}" })

      if response.success?
        cache_movie_data(response.parsed_response, current_language_code)

        cached = CachedMovie.find_by(movie_id: movie_id, language: current_language_code)

        @movie = if cached
                   movie_session.merge(
                     'title' => cached.title,
                     'overview' => cached.overview,
                     'poster_path' => cached.poster_path,
                     'backdrop_path' => cached.backdrop_path,
                     'vote_average' => cached.vote_average.to_f,
                     'vote_count' => cached.vote_count.to_i
                   )
                 else
                   movie_session
                 end
      else
        Rails.logger.warn "Falló al cachear película #{movie_id} en #{current_language_code} - Código: #{response.code} - Body: #{response.body}"
        @movie = movie_session
      end
    end

    current_user.watched_movies.find_or_create_by(movie_id: movie_id) if logged_in?

    CacheMovieJob.perform_later(movie_id, API_KEY, AUTH_TOKEN)
  end

  def store
    movie_data = params.require(:movie).permit(:id, :title, :overview, :poster_path, :backdrop_path, :vote_average,
                                               :vote_count, :rating, :total_votes).to_h
    session[:movie] = movie_data
    redirect_to details_movies_path
  end

  def cache_movie_data(movie, language)
    CachedMovie.upsert(
      {
        movie_id: movie['id'],
        language: language,
        title: movie['title'],
        overview: movie['overview'],
        poster_path: movie['poster_path'],
        backdrop_path: movie['backdrop_path'],
        vote_average: movie['vote_average'],
        vote_count: movie['vote_count'],
        updated_at: Time.current
      },
      unique_by: %i[movie_id language]
    )
  end

  private

  def current_language_code
    case I18n.locale
    when :es then 'es-MX'
    when :en then 'en-US'
    when :ko then 'ko-KR'
    when :zh then 'zh-CN'
    else 'en-US'
    end
  end
end
