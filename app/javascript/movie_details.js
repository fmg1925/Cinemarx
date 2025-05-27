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
      const score = event.target.dataset.score; // Csonseguir la puntuación
      const title = event.target.parentElement.getAttribute("title");
      const overview = event.target.parentElement.getAttribute("overview");
      const poster_path =
        event.target.parentElement.getAttribute("poster_path");
      const tmdb_vote_average =
        event.target.parentElement.getAttribute("vote-average");
      const tmdb_vote_count =
        event.target.parentElement.getAttribute("vote-count");
      const movieId = event.target.parentElement.dataset.movieId; // Conseguir la id de la película
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
              const voteAverageRaw = ratingDiv.getAttribute("vote-average");
              const voteAverage = parseFloat(voteAverageRaw) / 2;
              const dbRatings = parseFloat(data.ratings);
              const voteCount = parseInt(
                ratingDiv.getAttribute("vote-count"),
                10
              );
              const dbCount = parseInt(data.count, 10);
              const ratingsText = ratingDiv.getAttribute("ratings-text") || "";
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
          }function postToStoreMovies(movie) {
  // Crear formulario
  const form = document.createElement("form");
  form.method = "POST";
  form.action = "/movies/store";
  form.style.display = "none";

  // Agregar token CSRF
  const csrfToken = document
    .querySelector('meta[name="csrf-token"]')
    .getAttribute("content");
  const csrfInput = document.createElement("input");
  csrfInput.type = "hidden";
  csrfInput.name = "authenticity_token";
  csrfInput.value = csrfToken;
  form.appendChild(csrfInput);

  // Agregar parámetros movie (como campos ocultos)
  for (const key in movie) {
    if (movie.hasOwnProperty(key)) {
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = `movie[${key}]`;
      input.value = movie[key];
      form.appendChild(input);
    }
  }

  // Añadir el formulario al body y enviarlo
  document.body.appendChild(form);
  form.submit();
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
  const favoritos = document.querySelectorAll(".poster-button");
  let isSendingFavorite = false;
  favoritos.forEach((boton) => {
    if (boton.dataset.listenerAttached === "true") return;
    boton.dataset.listenerAttached = "true";
    boton.addEventListener("click", (event) => {
      if (isSendingFavorite) return;
      isSendingFavorite = true;
      const movieId = event.target.parentElement.dataset.movieId;
      const title = event.target.parentElement.getAttribute("title");
      const overview = event.target.parentElement.getAttribute("overview");
      const poster_path =
        event.target.parentElement.getAttribute("poster_path");
      const tmdb_vote_average =
        event.target.parentElement.getAttribute("vote_average");
      const tmdb_vote_count =
        event.target.parentElement.getAttribute("vote_count");
      fetch("/favorites", {
        // Enviar a la base de datos
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
            tmdb_vote_average: tmdb_vote_average,
            tmdb_vote_count: tmdb_vote_count,
          },
        }),
      })
        .then(async (response) => {
          const contentType = response.headers.get("content-type");
          if (
            !response.ok ||
            !contentType ||
            !contentType.includes("application/json")
          ) {
            window.location.href = "/login";
            return;
          }
          const data = await response.json();
          console.log("Respuesta: ", data);
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