xquery version "3.1";

module namespace path="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils/path";


(:~
: Returns the name of the file denoted by the given path.
: If the given path denotes a directory, the empty sequence is returned.
:
: @param $path the path to extract the file name from as xs:string
: @return the file name as xs:string?
:)
declare function path:get-filename($path as xs:string) as xs:string? {
    let $components := path:tokenize($path)
    let $name := $components[last()]
    return
        if (path:is-file-name($name)) then
            path:remove-file-extension($name, path:extract-file-extension($name))
        else
            ()
};

(:~
 : Tells if the given argument denotes a file name, i.e. is not a path.
 :
 : @param $name the path/file name to check as xs:string
 : @return true if the given argument is a file name, false otherwise as xs:boolean
 :)
declare function path:is-file-name($name as xs:string) as xs:boolean {
    not($name => contains("/")) and
    matches($name, "\.\w+$")
};

(:~
 : Tokenizes a given path into its components.
 : e.g. /foo/bar/baz will become ("foo", "bar", "baz")
 :
 : NB: . or .. will not be resolved.
 :     /foo/bar/../baz will become ("foo", "bar", "..", "baz")
 :
 : @param $path the path to tokenize
 : @return a sequence of strings
 :)
declare function path:tokenize($path as xs:string) as xs:string* {
    ($path => tokenize("/"))[. != ""]
};

(:~
: Extracts the file extension from a path.
:
: @param $path as xs:string
: @return the file extension as xs:string
:)
declare function path:extract-file-extension($path as xs:string) as xs:string {
    tokenize($path, "\.")[last()]
};

(:~
: Removes the file extension from a file name.
:
: @param $name as xs:string
: @param $extension as xs:string
: @return the file name without the extension as xs:string
:)
declare function path:remove-file-extension($name as xs:string, $extension as xs:string) as xs:string {
    replace($name, '\.' || $extension || '$', '')
};
