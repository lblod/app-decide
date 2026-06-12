# Running

A new validation round is by default started using the cron pattern defined in the `shacl-report.js` file. This is currently set to every night at 3am.

When the service (re)starts and the `RUN_NOW` environment parameter is set to `TRUE`, it automatically starts at start up.

## Adding a new validation

A new validation can be added in two ways:

1) Copy and rename an existing SHACL file in the `shacl` folder and adapt the prefixes, shape URI, target class, and properties
2) Copy and rename an existing SPARQL-based SHACL file in the `sparql` folder and adapt the prefixes, shape URI, target class, and SPARQL query.

In the `shacl-report.js` configuration file, an array of named graphs is defined where data will be retrieved for validation.

To validate your shape is working properly, following approach can be done:
1) write test data with a good and bad example to a temporary graph using an INSERT query
2) add this graph to the named graphs array in `shacl-report.js`
3) trigger the report (or restart the service) to start a new validation round
4) The results of the latest report can be found by checking `http://localhost/shacl-reports/shacl-reports/latest/issues`

Inspiration of adding and testing a new SHACL shape can be found in this PR: https://github.com/lblod/app-decide/pull/81

## Manual run

The SHACL validation can be manually triggered using following request:

```
POST /reports
Content-Type: "application/json"

{
  "data": {
    "attributes": {
      "reportName": "ELI validation of Decide"
   }
  }
}
```

## Environment variables

The following enviroment variables can be configured:
* `INSERT_BATCH_SIZE`: Number of triples that will be insert per batch. Defaults to `100`.
* `ONLY_KEEP_LATEST_REPORT`: Boolean that allows, when set to `true`, to only keep the most recent version of a report during its creation and to delete oder versions. Defaults to `false`
* `RUN_REPORT_NOW`: service automatically starts at start up

## SPARQL-based validation

SPARQL-based validations (defined in `./sparql` folder) can be activated by setting following env variable:

* `RUN_SPARQL_VALIDATIONS` Set to `true`to activate SPARQL validations. Default: `false`

This is disabled by default, because data gets inserted in a temporary graph, which triggers many Delta notifications that trigger other services.
