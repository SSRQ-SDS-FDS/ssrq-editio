/** Highlight text between the start and end markers emitted by ssrq-convert. */
function processSpanMarkers(root = document) {
  const spanMarkerTypes = [
    "add",
    "del",
  ];
  if (!globalThis.CSS?.highlights || !globalThis.Highlight) return;
  const highlight = new Highlight();
  for(const spanMarkerType of spanMarkerTypes){

    const endMarkers = new Map(
      [...root.querySelectorAll(`.${spanMarkerType}SpanEnd`)].map(marker => [marker.dataset[`${spanMarkerType}spanId`], marker])
    );

    for (const startMarker of root.querySelectorAll(`.${spanMarkerType}SpanStart`)) {
      const markerId = startMarker.dataset[`${spanMarkerType}spanId`];
      const endMarker = endMarkers.get(markerId);

      if (!markerId) {
        console.error(`Start marker is missing the "data-${spanMarkerType}span-id" attribute.`, startMarker);
        continue;
      }
      if (!endMarker) {
        console.error(`No closing marker found for ${spanMarkerType}Span ID "${markerId}".`, startMarker);
        continue;
      }
      if (startMarker.compareDocumentPosition(endMarker) &
          (Node.DOCUMENT_POSITION_DISCONNECTED | Node.DOCUMENT_POSITION_PRECEDING)) {
        console.error(`Invalid marker order for ${spanMarkerType}Span ID "${markerId}".`, startMarker, endMarker);
        continue;
      }

      const range = new Range();
      range.setStartAfter(startMarker);
      range.setEndBefore(endMarker);
      highlight.add(range);
    }

  }
  CSS.highlights.set("tei-spans", highlight);
}

export default processSpanMarkers;
