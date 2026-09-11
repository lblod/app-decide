Returns an overview of processed decisions for each pipeline (ELI, codelist SDG, codelist RMZ, NER, NEL)

# REST API

## GET /overview-query

### Response

#### 200 OK

Returns the overview in CSV format by default:

```
metric,Freiburg,Gent,Stadt Bamberg
1. ELI,8324,43721,5911
2. codelist SDG,500,750,382
3. codelist RMZ,8324,43721,382
4. NER,669,1750,1130
5. NEL,669,1750,2262
```

Optionally, JSON can be retrieved using the `format=json` query parameter (`/overview-query?format=json`)

