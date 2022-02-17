xquery version "3.1";

module namespace utils="http://ssrq-sds-fds.ch/utils";

declare %private function utils:pathcomp-remove-double-slashes($components as xs:string*) as xs:string* {
    for $comp at $i in $components
    let $comp-sanitized :=
        if ($i > 1 and starts-with($comp, "/")) then
            (: no double / in paths :)
            substring($comp, 2)
        else
            $comp
    return $comp-sanitized
};

declare %private function utils:pathcomp-remove-intermediate-dots($components as xs:string*) as xs:string* {
    for $comp in $components
    where $comp != "."
    return $comp
};

declare %private function utils:pathcomp-remove-backdirs($components as xs:string*) as xs:string* {
    (: ATTENTION: this function must only be called on a sequence of path tokens on which intermediate . have been removed already (cf. utils:pathcomp-remove-intermediate-dots) :)
    fold-left(
        $components,
        (),
        function ($l as xs:string*, $r as xs:string) {
            if ($r = "..") then
                if (count($l) > 0) then
                    $l[position() < last()]
                else
                    (: more .. than path components :)
                    ()
            else
                ($l, $r)
        })
};

(:~
 : Tells if the given argument denotes a file name, i.e. is not a path.
 :
 : @param $name the path/file name to check
 : @return boolean
 :)
declare function utils:is-file-name($name as xs:string) as xs:boolean {
    not($name => contains("/"))
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
declare function utils:path-tokenize($path as xs:string) as xs:string* {
    $path => tokenize("/")
};

(:~
 : Concatenates a sequence of path components to a path string.
 : To get an absolute path, the first component must be prefixed with a /.
 :
 : The function will remove double-slashes (e.g. foo//bar).
 :
 : NB: . or .. will not be resolved.
 :     /foo/bar/../baz will become ("foo", "bar", "..", "baz")
 :
 : @param $components a sequence of path components.
 : @return string
 :)
declare function utils:path-concat($components as xs:string*) as xs:string {
    $components
    => utils:pathcomp-remove-double-slashes()
    => string-join("/")
};

(:~
 : Tells if a given path is absolute.
 :
 : @param $path the path string to check
 : @return string
 :)
declare function utils:is-abs-path($path as xs:string) as xs:boolean {
    $path => starts-with("/")
};

(:~
 : A safer version of path-concat.
 : path-concat-safe will take the first path component as the "container" and
 : produce an error if evaluating the reslulting path would result in a path
 : that escapes the container, e.g. ("/some/safe/place", "../../foo.xml").
 :
 : The first component must thus be an absolute path.
 : Not passing an absolute path as the first item of the $components sequence is
 : considered an error.
 :
 : @param $components a non-empty sequence of path components
 : @return string
 :)
declare function utils:path-concat-safe($components as xs:string+) as xs:string {
    let $container := head($components)
    return
        if (utils:is-abs-path($container)) then
            let $result := utils:path-concat($components)
            let $real-result := utils:realpath($result, "")
            return
                if ($result = $real-result
                    or $real-result => starts-with($container || "/")) then
                    $result
                else
                    error(
                          QName('http://ssrq-sds-fds.ch/err',
                                'PathEscapesContainer'),
                          string-join($components, "/"))
        else
            error(
                  QName('http://ssrq-sds-fds.ch/err',
                        'AbsContainerPathRequired'),
                  $container)
};

(:~
 : Converts a given path to an absolute path (if not already), by interpreting
 : non-absolute paths relative to the given $cwd.
 :
 : @param $path the path
 : @param $cwd the anchor directory for relative paths
 : @return string
 :)
declare function utils:abspath($path as xs:string, $cwd as xs:string) as xs:string {
    if ($path => starts-with("/")) then
        $path
    else
        let $relpath :=
            if ($path => starts-with("./")) then
                substring($path, 3)
            else
                $path
        return
            utils:path-concat(($cwd, $path))
};

(:~
 : Pendant to realpath(3) for eXist.
 : This function resolves . and .. path components and removes double-slashes
 : from the paths.
 :
 : @param $path the path
 : @param $cwd anchor for relative paths
 : @return string
 :)
declare function utils:realpath($path as xs:string, $cwd as xs:string) as xs:string {
    utils:abspath($path, $cwd)
    => utils:path-tokenize()
    => utils:pathcomp-remove-double-slashes()
    => utils:pathcomp-remove-intermediate-dots()
    => utils:pathcomp-remove-backdirs()
    => utils:path-concat()
};

(:~
 : The coalesce function evaluates the expressions $a and $b and always returns
 : the first truthy value.
 :
 : @param $a the first value
 : @param $b the second value
 : @return either $a or $b
 :)
declare function utils:coalesce($a, $b) {
  if ($a) then $a else $b
};
