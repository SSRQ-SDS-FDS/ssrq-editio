xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";

declare namespace json="http://www.json.org";

declare option exist:serialize "method=json media-type=application/json";

declare function local:upload($name, $data) {
    let $path :=
        (
            xmldb:store($config:temp-root, $name, $data),
            sm:chmod(xs:anyURI(utils:path-concat-safe(($config:temp-root, $name))), "rw-r-----")
        )
    return
        map {
            "files": array {
                map {
                    "name": $name,
                    "path": substring-after($path, $config:data-root || "/"),
                    "type": xmldb:get-mime-type($path),
                    "size": xmldb:size($config:temp-root, $name)
                }
            }
        }
};

let $name := request:get-uploaded-file-name("files[]")
let $data := request:get-uploaded-file-data("files[]")
return
    if (count($name) > 1) then
       map { "error": "only one file, please" }
    else if (not(utils:is-file-name($name))) then
        map { "error": "only a filename, please, no paths" }
    else
        try {
            local:upload($name, $data)
        } catch * {
            (
                response:set-status-code(
                    if ($err:description => contains('Write permission is not granted')) then 403 else 500
                ),
                map {
                    "name": $name,
                    "error": $err:description,
                    "code": $err:code
                }
            )[1]
        }
