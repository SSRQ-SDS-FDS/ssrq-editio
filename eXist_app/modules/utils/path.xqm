xquery version "3.1";

module namespace path="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils/path";

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
