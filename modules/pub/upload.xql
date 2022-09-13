xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace json="http://www.json.org";
declare namespace ssrq-upload="http://ssrq-sds-fds.ch/exist/apps/ssrq/upload";

declare option exist:serialize "method=json media-type=application/json";

declare function local:upload($name, $data) {
    let $path :=
        (
            xmldb:store($config:temp-root, $name, $data),
            sm:chmod(xs:anyURI(utils:path-concat-safe(($config:temp-root, $name))), "rw-r--r--")
        )
    return
        map {
            "files": array {
                map {
                    "name": $name,
                    "path": utils:path-concat(('temp', $name => replace('.xml', '.html'))),
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
            let $id := parse-xml(util:base64-decode($data))//tei:seriesStmt[@xml:id="ssrq-sds-fds"]/tei:idno/text()
            return
                if ($id => empty()) then
                    error(xs:QName("ssrq-upload:id-missing"), 'ID missing. You need to assign an tei:idno before uploading.')
                else if (collection($config:data-root)//tei:TEI[.//tei:idno/text() = $id][not(root(.) => document-uri() => contains($config:temp-root))] => empty()) then
                    local:upload($id ||'.xml', $data)
                else
                    error(xs:QName("ssrq-upload:error"), ('The file with the id', $id, 'already exists and is a published document!') => string-join(' '))
        } catch ssrq-upload:id-missing {
                (
                response:set-status-code(
                    400
                ),
                map {
                    "name": $name,
                    "error": $err:description,
                    "code": $err:code
                }
            )[1]
        }
        catch ssrq-upload:error {
                (
                response:set-status-code(
                    403
                ),
                map {
                    "name": $name,
                    "error": $err:description,
                    "code": $err:code
                }
            )[1]
        }
        catch * {
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
