function copySelections(selections) {
  return Object.fromEntries(
    Object.entries(selections).map(([name, values]) => [name, [...values]]),
  );
}

function searchFilters(filters) {
  return {
    open: false,
    defaults: {},
    selected: {},
    applied: {},

    init() {
      for (const filter of filters) {
        this.defaults[filter.name] = filter.options.map((option) => option.value);
        this.selected[filter.name] = filter.options
          .filter((option) => option.selected)
          .map((option) => option.value);
      }
      this.applied = copySelections(this.selected);
    },

    cancel() {
      this.selected = copySelections(this.applied);
      this.open = false;
    },

    reset() {
      this.selected = copySelections(this.defaults);
    },

    apply() {
      this.applied = copySelections(this.selected);
      this.open = false;
    },

    preventEmptySelection(event, name, value) {
      if (this.selected[name].length === 1 && this.selected[name].includes(value)) {
        event.preventDefault();
      }
    },

    isApplied(name, value) {
      return (
        this.applied[name].length < this.defaults[name].length &&
        this.applied[name].includes(value)
      );
    },

    remove(name, value) {
      this.applied[name] =
        this.applied[name].length === 1
          ? [...this.defaults[name]]
          : this.applied[name].filter((item) => item !== value);
      this.selected[name] = [...this.applied[name]];
      this.$nextTick(() => this.$refs.searchForm.requestSubmit());
    },
  };
}

export default searchFilters;
