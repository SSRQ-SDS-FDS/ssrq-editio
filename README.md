# Quellenportal der Sammlung Schweizerischer Rechtsquellen (SSRQ)

This is the main application repository for SSRQ. 

## Building

Just run "ant" in the root of the cloned repository and a `.xar` package will be created in `build`, which you can then deploy into eXist via the dashboard.

The data for this application resides in a different package. You thus need to clone
[ssrq-data](http://gitlab.exist-db.org/SSRQ/ssrq-data) and deploy it in addition to this xar.

## Issue Reporting

Please report issues into the [issue tracker](http://gitlab.exist-db.org/SSRQ/ssrq/issues).

**Note to developers**: in addition to our time tracker, please track the time you spent on an issue by adding a comment with a slash command `/spent`, e.g.

```
/spend 4h
```

Before starting work on an issue, make sure there's a time estimate assigned to it.