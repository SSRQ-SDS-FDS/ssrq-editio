/**
 * Represents the DOM range between a matching start and end marker.
 *
 * Provides a method for determining whether a DOM node lies outside,
 * partially inside, or completely inside the marked range.
 */
class MarkerRange{
  static nodeState = Object.freeze({
    OUTSIDE: Symbol(),
    PARTIAL: Symbol(),
    INSIDE: Symbol(),
  });

  #range;

  constructor(startElement, endElement){
    this.#range = document.createRange();
    this.#range.setStartAfter(startElement);
    this.#range.setEndBefore(endElement);
  }

  /**
   * Determines whether a node is outside, partially inside, or completely
   * inside the marker range.
   */
  checkNode(node){
    // check if node is outside of range
    if(!this.#range.intersectsNode(node)){
      return MarkerRange.nodeState.OUTSIDE;
    }
    
    // Check if the entire node is contained within the range
    const nodeRange = document.createRange();
    nodeRange.selectNode(node);
    if(
      this.#range.compareBoundaryPoints(Range.START_TO_START, nodeRange) <= 0 &&
      this.#range.compareBoundaryPoints(Range.END_TO_END, nodeRange) >= 0
    ){
      return MarkerRange.nodeState.INSIDE;
    }
    return MarkerRange.nodeState.PARTIAL;
  }
}

/**
 * Finds the nearest ancestor of the start marker that also contains the
 * matching end marker.
 */
function getNearestCommonAncestor(start, end){
  let node = start.parentElement;

  while(node){
    if(node.contains(end)){
      return node;
    }
    node = node.parentElement;
  }

  return null;
}

/**
 * Wraps a DOM node in a newly created element with the supplied CSS classes.
 */
function wrapInElement( node, classNames, tagName = "span" ){
  const newElement = document.createElement(tagName);
  newElement.classList.add(...classNames);
  node.replaceWith(newElement);
  newElement.appendChild(node);

  return newElement;
}

/**
 * Finds the end marker whose data attribute matches the supplied marker ID.
 */
function findMatchingEndMarker(spanType, markerId) {
  const datasetKey = `${spanType.toLowerCase()}Id`;
  const endMarkers = document.querySelectorAll(
    `span.${spanType}End`
  );

  for (const endMarker of endMarkers) {
    if (endMarker.dataset[datasetKey] === markerId) {
      return endMarker;
    }
  }

  return null;
}

/**
 * Recursively processes the children of a node that intersect the marker
 * range.
 *
 * Text nodes are wrapped in an element so that CSS classes can be applied.
 * Element nodes that lie completely inside the range receive the classes
 * directly. Partially intersecting elements are traversed recursively.
 */
function processRangeChildren(node, spanRange, classNames) {
  for (const child of [...node.childNodes]) {
    const nodeState = spanRange.checkNode(child);

    if (nodeState === MarkerRange.nodeState.OUTSIDE) {
      continue;
    }

    if (child.nodeType === Node.TEXT_NODE) {
      if (child.nodeValue.trim() === "") {
        continue;
      }

      const alreadyWrapped = classNames.every(
        cl => child.parentElement?.classList.contains(cl)
      );

      if (!alreadyWrapped) {
        wrapInElement(child, classNames, "span");
      }

      continue;
    }

    if (child.nodeType !== Node.ELEMENT_NODE) {
      continue;
    }

    if (nodeState === MarkerRange.nodeState.INSIDE) {
      child.classList.add(...classNames);
      continue;
    }

    processRangeChildren(child, spanRange, classNames);
  }
}

/**
 * Processes matching span marker pairs and marks all DOM nodes between them.
 *
 * For each marker pair, the function creates a DOM Range, determines the
 * nearest common ancestor, and recursively processes all intersecting nodes.
 */
function processSpanMarkers() {
  // TODO: Add support and tests for delSpan and damageSpan.
  const spanTypes = ["addSpan"];

  for (const spanType of spanTypes) {
    const startMarkers = document.querySelectorAll(
      `span.${spanType}Start`
    );

    const datasetKey = `${spanType.toLowerCase()}Id`;
    const dataAttribute = `data-${spanType.toLowerCase()}-id`;
    const classNames = ["inline-content", `tei-${spanType}`];

    for (const startMarker of startMarkers) {
      const markerId = startMarker.dataset[datasetKey];

      if (markerId === undefined || markerId === "") {
        console.error(
          `Start marker is missing the "${dataAttribute}" attribute.`,
          startMarker
        );
        continue;
      }

      const endMarker = findMatchingEndMarker(
        spanType,
        markerId
      );

      if (endMarker === null) {
        console.error(
          `No closing marker found for ${spanType} ID "${markerId}".`,
          startMarker
        );
        continue;
      }

      const commonRoot = getNearestCommonAncestor(
        startMarker,
        endMarker
      );

      if (commonRoot === null) {
        console.error(
          `Markers for ${spanType} ID "${markerId}" have no common ancestor.`,
          startMarker,
          endMarker
        );
        continue;
      }

      const spanRange = new MarkerRange(
        startMarker,
        endMarker
      );

      processRangeChildren(
        commonRoot,
        spanRange,
        classNames
      );
    }
  }
}

document.addEventListener("DOMContentLoaded", processSpanMarkers, { once: true } );
