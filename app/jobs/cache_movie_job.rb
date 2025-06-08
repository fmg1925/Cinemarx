class CacheMovieJob < ApplicationJob
  queue_as :low_priority

  LANGUAGE_MAP = {
    es: 'es-MX',
    en: 'en-US',
    ko: 'ko-KR',
    zh: 'zh-CN'
  }

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

  def perform(movie_id, api_key, auth_token)
    uncached_languages = LANGUAGE_MAP.values.reject do |lang_code|
      CachedMovie.exists?(movie_id: movie_id, language: lang_code)
    end

    return if uncached_languages.empty?

    uncached_languages.each do |lang_code|
      movie_url = "https://api.themoviedb.org/3/movie/#{movie_id}?language=#{lang_code}&api_key=#{api_key}"
      response = HTTParty.get(movie_url, headers: { 'Authorization' => "Bearer #{auth_token}" })

      if response.success?
        cache_movie_data(response.parsed_response, lang_code)
      else
        Rails.logger.warn "Falló al cachear película #{movie_id} en #{lang_code} - Código: #{response.code} - Body: #{response.body}"
      end
    end
  end
end
