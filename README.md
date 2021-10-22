# TEI-Quellenportal der Sammlung Schweizerischer Rechtsquellen (SSRQ)

This is the main application repository for SSRQ.

## Building

Just run `ant` in the root of the cloned repository and a `.xar` package will be
created in `build`, which you can then deploy into eXist via the dashboard.

The data for this application resides in a different package. You thus need to
clone `ssrq-data` and deploy it prior to this xar.

## Issue Reporting

Please report issues in [Redmine](https://histhub.ssrq-sds-fds.ch/redmine/projects/portal-tei-publisher).
