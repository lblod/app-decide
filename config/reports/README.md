# Running

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

# SPARQL-based validation

SPARQL-based validations (defined in `./sparql` folder) can be activated by setting following env variable:

* `RUN_SPARQL_VALIDATIONS` Set to `true`to activate SPARQL validations. Default: `false`

This is disabled by default, because data gets inserted in a temporary graph, which triggers many Delta notifications that trigger other services.
