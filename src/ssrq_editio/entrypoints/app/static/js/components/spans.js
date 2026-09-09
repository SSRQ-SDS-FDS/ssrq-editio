/** Highlight text between the start and end markers emitted by ssrq-convert. */
function processSpanMarkers(root = document) {
  if (!globalThis.CSS?.highlights || !globalThis.Highlight) return;

  const endMarkers = new Map(
    [...root.querySelectorAll(".addSpanEnd")].map(marker => [marker.dataset.addspanId, marker])
  );
  const highlight = new Highlight();

  for (const startMarker of root.querySelectorAll(".addSpanStart")) {
    const markerId = startMarker.dataset.addspanId;
    const endMarker = endMarkers.get(markerId);

    if (!markerId) {
      console.error('Start marker is missing the "data-addspan-id" attribute.', startMarker);
      continue;
    }
    if (!endMarker) {
      console.error(`No closing marker found for addSpan ID "${markerId}".`, startMarker);
      continue;
    }
    if (startMarker.compareDocumentPosition(endMarker) &
        (Node.DOCUMENT_POSITION_DISCONNECTED | Node.DOCUMENT_POSITION_PRECEDING)) {
      console.error(`Invalid marker order for addSpan ID "${markerId}".`, startMarker, endMarker);
      continue;
    }

    const range = new Range();
    range.setStartAfter(startMarker);
    range.setEndBefore(endMarker);
    highlight.add(range);
  }

  CSS.highlights.set("tei-additions", highlight);
}

document.addEventListener("DOMContentLoaded", () => processSpanMarkers(), { once: true });
