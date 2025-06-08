document.addEventListener("turbo:load", () => {
  const params = new URLSearchParams(window.location.search);
  const query = params.get("query");
  if (query) {
    setTimeout(() => {
      const input = document.getElementById("search");
      if (input) {
        input.value = query; // Escribir la búsqueda en el textbox al cargar la página
      }
    }, 50);
  }
});