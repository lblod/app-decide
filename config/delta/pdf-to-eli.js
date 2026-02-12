export default [
    {
        match: {
          predicate: {
            type: "uri",
            value: "http://www.w3.org/ns/adms#status",
          },
          object: {
            type: "uri",
            value: "http://redpencil.data.gift/id/concept/JobStatus/scheduled",
          },
        },
        callback: {
          method: "POST",
          url: "http://entity-linking/delta",
        },
        options: {
          resourceFormat: "v0.0.1",
          gracePeriod: 1000,
          ignoreFromSelf: true,
          sendMatchesOnly: true,
        },
      },
      {
        match: {
          predicate: {
            type: "uri",
            value: "http://www.w3.org/ns/adms#status",
          },
          object: {
            type: "uri",
            value: "http://redpencil.data.gift/id/concept/JobStatus/scheduled",
          },
        },
        callback: {
          method: "POST",
          url: "http://pdf-content/delta",
        },
        options: {
          resourceFormat: "v0.0.1",
          gracePeriod: 1000,
          ignoreFromSelf: true,
          sendMatchesOnly: true,
        },
      },
      {
        match: {
          predicate: {
            type: "uri",
            value: "http://www.w3.org/ns/adms#status",
          },
          object: {
            type: "uri",
            value: "http://redpencil.data.gift/id/concept/JobStatus/scheduled",
          },
        },
        callback: {
          method: "POST",
          url: "http://pdf-scraper/delta",
        },
        options: {
          resourceFormat: "v0.0.1",
          gracePeriod: 1000,
          ignoreFromSelf: true,
          sendMatchesOnly: true,
        },
      },
  ];