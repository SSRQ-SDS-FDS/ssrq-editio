/*
    Function to handle, if the "to-top" button should be visible or not.
    Depends on alpine.js
*/
function topButtonScrollHandler() {
  return {
    isButtonVisible: false,
    init() {
      this.observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          this.isButtonVisible = !entry.isIntersecting;
        });
      });

      const watched = document.querySelector(".watch-with-top-button");
      if (watched) {
        this.observer.observe(watched);
      }
    },
    scrollToTop() {
      window.scrollTo({ top: 0, behavior: "smooth" });
    },
  };
}

export default topButtonScrollHandler;
