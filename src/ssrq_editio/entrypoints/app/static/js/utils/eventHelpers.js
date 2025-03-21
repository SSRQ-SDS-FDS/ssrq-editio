/**
 * Removes empty parameters from the `parameters` object within the `detail` property of the given event.
 * Empty parameters are those with values that are an empty string, `null`, or `undefined`.
 * Functions within the `parameters` object are ignored and not removed.
 *
 * @param {Event} evt - The event object containing a `detail` property with a `parameters` object to be cleaned.
 */
const removeEmptyParameters = function (evt) {
  for (const param in evt.detail.parameters) {
    const value = evt.detail.parameters[param];

    if (value instanceof Function) continue;

    if (value === '' || value === null || value === undefined) {
      delete evt.detail.parameters[param];
    }
  }
};

export { removeEmptyParameters };
