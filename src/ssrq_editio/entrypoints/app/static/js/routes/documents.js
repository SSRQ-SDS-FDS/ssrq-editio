document.addEventListener("alpine:init", () => {
  Alpine.data("placesStdNames", () => ({
    async fetchAndInsert() {
      /**
       * @type {string}
       */
      const apiBase = this.$el.dataset.endpoint;
      /**
       * @type {string}
       */
      const apiLang = this.$el.dataset.lang;
      for (const place of [...this.$el.querySelectorAll("[data-place-ref]")]) {
        /**
         * @type {string}
         */
        const ref = place.dataset.placeRef;
        const url = `${apiBase}/${ref}?lang=${apiLang}`;
        try {
          const response = await fetch(url);
          /**
           * @typedef {Object} Data
           * @property {string} id - The id of the place
           * @property {string} stdName - The standard name of the place
           */

          /**
           * @type {Data}
           */
          const data = await response.json();
          place.innerHTML = data.stdName;
        } catch (error) {
          console.error(`Error fetching ${url} : ${error}`);
        }
      }
    },
  }));
});
