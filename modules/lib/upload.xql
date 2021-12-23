xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

declare namespace json="http://www.json.org";

declare option exist:serialize "method=json media-type=application/json";

declare function local:upload($root, $paths, $payloads) {
    (: FIXME: collection-uri should be dynaimc so that it doesn't break when temp is moved :)
    let $collection-uri := $config:app-root
    let $paths :=
        for-each-pair($paths, $payloads, function($path, $data) {
            if (ends-with($path, ".odd")) then
                xmldb:store($config:temp-root, $path, $data)
            else (
                xmldb:store($config:temp-root || "/" || $root, $path, $data),
                sm:chmod(xs:anyURI($config:temp-root || "/" || $root || "/" || $path), "rw-r-----")
            )
        })
    return
        map {
            "files": array {
                for $path in $paths
                let $url := substring-after($path, $collection-uri || "/")
                return
                    map {
                        "name": $path,
                        "path": $url,
                        "type": xmldb:get-mime-type($path),
                        "size": xmldb:size($config:temp-root, substring-after($path, $config:temp-root || "/"))
                    }
            }
        }
};

let $name := request:get-uploaded-file-name("files[]")
let $data := request:get-uploaded-file-data("files[]")
let $root := request:get-parameter("root", "")
return
    try {
        local:upload($root, $name, $data)
    } catch * {
        map {
            "name": $name,
            "error": $err:description
        }
    }
