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