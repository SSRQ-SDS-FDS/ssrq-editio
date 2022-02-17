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

declare function utils:is-file-name($name as xs:string) as xs:boolean {
    not($name => contains("/"))
};

declare function utils:path-tokenize($path as xs:string) as xs:string* {
    $path => tokenize("/")
};

declare function utils:path-concat($components as xs:string*) as xs:string {
    $components
    => utils:pathcomp-remove-double-slashes()
    => string-join("/")
};

declare function utils:is-abs-path($path as xs:string) as xs:boolean {
    $path => starts-with("/")
};

declare function utils:path-concat-safe($components as xs:string+) as xs:string {
    (: the first component will be used as the sandbox and must be an absolute path :)
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

declare function utils:realpath($path as xs:string, $cwd as xs:string) as xs:string {
    utils:abspath($path, $cwd)
    => utils:path-tokenize()
    => utils:pathcomp-remove-double-slashes()
    => utils:pathcomp-remove-intermediate-dots()
    => utils:pathcomp-remove-backdirs()
    => utils:path-concat()
};
