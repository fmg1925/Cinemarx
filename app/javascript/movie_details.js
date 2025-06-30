document.addEventListener("turbo:load", () => {
  // Cuando cargue la página
  const stars = document.querySelectorAll(".star"); // Conseguir las estrellas
  let isSending = false;
  stars.forEach((star) => {
    if (star.dataset.listenerAttached === "true") return;
    star.dataset.listenerAttached = "true";

    star.addEventListener("click", (event) => {
      // Hacer las estrellas clickeables
      if (isSending) return;
      isSending = true;
      const score = event.target.dataset.score; // Conseguir la puntuación
      const ratingContainer = event.target.closest('.movie-details-rating');
      const movieId = ratingContainer.dataset.movieId;
      const title = ratingContainer.dataset.title;
      const overview = ratingContainer.dataset.overview;
      const poster_path = ratingContainer.dataset.posterPath;
      const backdrop_path = ratingContainer.dataset.backdropPath;
      const tmdb_vote_average = ratingContainer.dataset.voteAverage;
      const tmdb_vote_count = ratingContainer.dataset.voteCount;
      fetch("/ratings", {
        // Enviar a la base de datos
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document
            .querySelector("meta[name='csrf-token']")
            .getAttribute("content"),
        },
        body: JSON.stringify({
          rating: {
            score: score,
            movie_id: movieId,
          },
          movie: {
            title: title,
            overview: overview,
            poster_path: poster_path,
            backdrop_path: backdrop_path,
            tmdb_vote_average: tmdb_vote_average,
            tmdb_vote_count: tmdb_vote_count,
          },
        }),
      })
        .then((response) => {
          if (response.redirected) {
            // Redigir al login si el usuario no ha iniciado sesión
            window.location.href = response.url;
          } else if (!response.ok) {
            throw new Error("Request failed");
          } else {
            return response.json();
          }
        })
        .then((data) => {
          if (data) {
            const ratingDiv = document.querySelector(
              // Conseguir el contenedor del rating de la película
              `.movie-details-rating[data-movie-id="${movieId}"]`
            );
            if (ratingDiv) {
              const voteAverageRaw = ratingDiv.dataset.voteAverage;
              const voteAverage = parseFloat(voteAverageRaw) ? parseFloat(voteAverageRaw) / 2 : 0;
              const dbRatings = parseFloat(data.ratings) || 0;
              const voteCount = parseInt(ratingDiv.dataset.voteCount, 10);
              const dbCount = parseInt(data.count, 10) || 0;
              const ratingsText = ratingDiv.dataset.ratingsText || "";
              const totalRatingSum =
                voteAverage * voteCount + dbRatings * dbCount;
              const totalVotes = voteCount + dbCount;
              const combinedAverage =
                totalVotes > 0 ? totalRatingSum / totalVotes : 0;
              const formattedAverage = combinedAverage.toFixed(1);
              // Combinar los ratings de la API con los de la base de datos
              ratingDiv.querySelector(
                ".rating-score"
              ).textContent = `${formattedAverage} / 5 (${totalVotes} ${ratingsText})`;
              const estrellas = ratingDiv.querySelectorAll(".fa-star");
              estrellas.forEach((estrella, index) => {
                estrella.style.color = index < score ? "#ffae10" : "";
              });
            }
          }
        })
        .catch((error) => {
          console.error("There was a problem with the fetch operation:", error);
        })
        .finally(() => {
          isSending = false;
        });
    });
  });

  // Favoritos

  const favoritos = document.querySelectorAll(".details-poster-button");
  let isSendingFavorite = false;

  favoritos.forEach((boton) => {
    if (boton.dataset.listenerAttached === "true") return;
    boton.dataset.listenerAttached = "true";

    boton.addEventListener("click", (event) => {
      if (isSendingFavorite) return;
      isSendingFavorite = true;

      const movieElement = event.target.parentElement;
      const movieId = movieElement.dataset.movieId;
      const title = movieElement.dataset.title;
      const overview = movieElement.dataset.overview;
      const poster_path = movieElement.dataset.posterPath;
      const backdrop_path = movieElement.dataset.backdropPath;
      const tmdb_vote_average = movieElement.dataset.voteAverage;
      const tmdb_vote_count = movieElement.dataset.voteCount;

      fetch("/favorites", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document
            .querySelector("meta[name='csrf-token']")
            .getAttribute("content"),
          Accept: "application/json",
        },
        body: JSON.stringify({
          movie_id: movieId,
          movie: {
            title: title,
            overview: overview,
            poster_path: poster_path,
            backdrop_path: backdrop_path,
            tmdb_vote_average: tmdb_vote_average,
            tmdb_vote_count: tmdb_vote_count,
          },
        }),
      })
        .then(async (response) => {
          if (response.redirected) {
            window.location.href = "/login";
            return;
          }
        })
        .catch((error) => {
          console.error("Error:", error);
        })
        .finally(() => {
          isSendingFavorite = false;
          const botonFavorito = event.target;
          botonFavorito.textContent =                                       
            botonFavorito.textContent == "💛" ? "❤️" : "💛";
        });
    });
  });
});
