module namespace error="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/error";

declare function error:display($node as node(), $model as map(*)) as node() {
    element { node-name($node) } {
        $node/@* except $node/@data-template,
        $model?description
    }
};
