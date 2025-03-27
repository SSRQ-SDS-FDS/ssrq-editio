const langSwitch = function () {
  return {
    updateLanguage(evt) {
      let currentURL = new URL(window.location.href);
      let newURL = new URL(evt.target.href);

      // Update the new URL with the current URL's query-parameters
      // except for the 'lang' parameter which is already set in the new URL
      for (let [key, value] of currentURL.searchParams) {
        if (key === 'lang') continue;
        newURL.searchParams.set(key, value);
      }

      window.location.href = newURL.href;
    },
  };
};

export default langSwitch;
