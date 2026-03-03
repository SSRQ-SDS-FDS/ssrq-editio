const dateRange = function (
  selectedMinYear = 500,
  selectedMaxYear = 1798,
  min = 500,
  max = 1798,
  eventName = 'date-range-changed',
  startParamName = 'range_start',
  endParamName = 'range_end',
  htmxContainerId = null,
) {
  return {
    selectedMinYear: selectedMinYear,
    selectedMaxYear: selectedMaxYear,
    minYear: min,
    maxYear: max,
    minthumb: 0,
    maxthumb: 0,
    init_done: false,

    init() {
      this.init_done = false;
      this.mintrigger();
      this.maxtrigger();

      if (htmxContainerId !== null) {
        const container = document.querySelector(`#${htmxContainerId}`);
        if (container !== null) {
          container.addEventListener('htmx:afterSettle', () => {
            this.updateURL();
          });
        }
      }

      this.updateURL();
      this.init_done = true;
    },

    mintrigger() {
      this.selectedMinYear = this.selectedMinYear;

      if (
        this.selectedMinYear >= this.minYear &&
        this.selectedMinYear < this.selectedMaxYear &&
        this.selectedMinYear < this.maxYear
      ) {
        this.minthumb =
          ((this.selectedMinYear - this.minYear) /
            (this.maxYear - this.minYear)) *
          100;
        this.dispatchDateRangeEvent();
      }
    },
    maxtrigger() {
      this.selectedMaxYear = this.selectedMaxYear;
      if (
        this.selectedMaxYear > this.minYear &&
        this.selectedMaxYear > this.selectedMinYear &&
        this.selectedMaxYear <= this.maxYear
      ) {
        this.maxthumb =
          100 -
          ((this.selectedMaxYear - this.minYear) /
            (this.maxYear - this.minYear)) *
            100;
        this.dispatchDateRangeEvent();
      }
    },
    dispatchDateRangeEvent() {
      if (this.init_done) {
        this.$dispatch(eventName, {
          range_start: this.selectedMinYear,
          range_end: this.selectedMaxYear,
        });
      }
    },
    updateURL() {
      if (
        this.selectedMinYear == this.minYear &&
        this.selectedMaxYear == this.maxYear
      ) {
        const url = new URL(window.location.href);
        url.searchParams.delete(startParamName);
        url.searchParams.delete(endParamName);
        window.history.replaceState({}, '', url);
      }
    },
  };
};

export default dateRange;
