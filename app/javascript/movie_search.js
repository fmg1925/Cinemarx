// app/javascript/movie_search.js

document.addEventListener("DOMContentLoaded", function () {
  // Cuando se cargue el DOM
  const params = new URLSearchParams(window.location.search); // Conseguir la búsqueda de la URL
  const query = params.get("query");
  if (query) {
    const input = document.getElementById("movie-search-textbox"); // Forzar sincronización del textbox con la búsqueda en el link
    if (input) {
      input.value = query;
    }
  }
});
