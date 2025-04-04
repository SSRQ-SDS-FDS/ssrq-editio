const dateRange = function (
  selectedMinYear = 500,
  selectedMaxYear = 1798,
  min = 500,
  max = 1798,
  eventName = 'date-range-changed',
  startParamName = 'range_start',
  endParamName = 'range_end'
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
          range_start: this.selectedMaxYear,
          range_end: this.selectedMaxYear,
        });
      }

      /* Remove the URL parameters after the user has selected the full range,
      uses a timeout to allow the event to be dispatched first
      and handled by HTMX

      ToDo: This is a bit of a hack, maybe listen to events by htmx instead?
      */
      setTimeout(() => {
        this.updateURL();
      }, 750);
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
