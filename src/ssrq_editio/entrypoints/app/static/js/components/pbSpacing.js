const PB_WRAPPER_SELECTOR = 'span.tei-pb';

/*
  The XSLT output keeps the original XML whitespace semantics. That is usually
  correct, but page-break markers are awkward because they may sit flush against
  adjacent content when the source XML is formatted without literal spaces
  around `tei:pb`. We therefore fix spacing at the DOM level instead of changing
  the transformed content itself: if neighboring rendered content already
  contributes whitespace, we leave it untouched; otherwise we add a small visual
  margin on the missing side only.
*/
function isPbWrapper(element) {
  if (!element.matches(PB_WRAPPER_SELECTOR)) {
    return false;
  }

  /*
    The outer wrapper and nested popup fragments both use spans, so selecting
    `.tei-pb` alone is too broad. A real page-break wrapper is the one that
    directly contains the visible marker (`button.tei-pb` or plain `span.tei-pb`)
    together with its popup metadata.
  */
  const hasMarker = element.querySelector(':scope > button.tei-pb, :scope > span.tei-pb') !== null;
  const hasPopup = element.querySelector(':scope > .popup, :scope > popup') !== null;

  return hasMarker && hasPopup;
}

function getBoundaryContent(node, direction) {
  let sibling = direction === 'previous' ? node.previousSibling : node.nextSibling;

  while (sibling) {
    if (sibling.nodeType === Node.TEXT_NODE) {
      return sibling.textContent ?? '';
    }

    if (sibling.nodeType === Node.ELEMENT_NODE) {
      /*
        Adjacent inline markup such as entity spans still contributes visible
        text flow. Looking at `textContent` gives us a practical answer to
        “would the reader already see whitespace here?” without having to
        reproduce the entire inline rendering logic.
      */
      return sibling.textContent ?? '';
    }

    sibling = direction === 'previous' ? sibling.previousSibling : sibling.nextSibling;
  }

  return '';
}

function updatePbSpacing(pbWrapper) {
  const leftContent = getBoundaryContent(pbWrapper, 'previous');
  const rightContent = getBoundaryContent(pbWrapper, 'next');

  /*
    We only compensate when the neighboring rendered content touches the page
    break directly. If the left side already ends with whitespace or the right
    side already starts with whitespace, we do nothing so existing spacing is
    not visually doubled.
  */
  const needsSpaceLeft = leftContent.length > 0 && !/\s$/.test(leftContent);
  const needsSpaceRight = rightContent.length > 0 && !/^\s/.test(rightContent);

  pbWrapper.classList.toggle('tei-pb-needs-space-left', needsSpaceLeft);
  pbWrapper.classList.toggle('tei-pb-needs-space-right', needsSpaceRight);
}

function syncPbSpacing(root = document) {
  const wrappers = [];

  if (root.nodeType === Node.ELEMENT_NODE && isPbWrapper(root)) {
    wrappers.push(root);
  }

  if (root.nodeType === Node.ELEMENT_NODE || root === document) {
    wrappers.push(...root.querySelectorAll(PB_WRAPPER_SELECTOR));
  }

  wrappers.filter(isPbWrapper).forEach(updatePbSpacing);
}

function initPbSpacing() {
  syncPbSpacing(document);

  /*
    Transcript fragments are not guaranteed to be final at initial page load:
    Alpine/htmx interactions can replace or reinsert DOM subtrees later on.
    The observer keeps newly added `tei:pb` wrappers aligned with the same
    spacing rule without forcing each caller to remember a manual resync step.
  */
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach((node) => {
        if (node.nodeType === Node.ELEMENT_NODE) {
          syncPbSpacing(node);
        }
      });
    });
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });
}

export default initPbSpacing;
