/*
    Function to handle, to scroll a element smoothly into view.
    Depends on alpine.js
*/
function smoothScrollHandler(targetId) {
  return {
    target: null,

    init() {
      this.target = document.getElementById(targetId);
    },

    trigger: {
      ["@click"]() {
        if (this.target) {
          this.scrollIntoView(this.target);
        }
      },
    },
    scrollIntoView(element) {
      element.scrollIntoView({
        behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches
          ? "instant"
          : "smooth",
        block: "start",
      });
      element.focus({ preventScroll: true });
    },
  };
}

export default smoothScrollHandler;
