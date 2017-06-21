import module namespace m='http://www.tei-c.org/pm/models/ssrq/epub' at '/db/apps/ssrq/transform/ssrq-epub.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["../transform/ssrq.css"],
    "collection": "/db/apps/ssrq/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)