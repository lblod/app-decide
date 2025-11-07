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
          url: "http://harvest_diff/delta",
        },
        options: {
          resourceFormat: "v0.0.1",
          gracePeriod: 1000,
          ignoreFromSelf: true,
          sendMatchesOnly: false,
        },
      },
      {
        match: {
          predicate: {
            type: "uri",
            value: "http://www.w3.org/ns/adms#status",
          },
        },
        callback: {
          method: "POST",
          url: "http://job-controller/delta",
        },
        options: {
          resourceFormat: "v0.0.1",
          gracePeriod: 1000,
          ignoreFromSelf: true,
          retry: 3,
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
          url: "http://harvest_sameas/delta",
        },
        options: {
          resourceFormat: "v0.0.1",
          gracePeriod: 1000,
          ignoreFromSelf: true,
          sendMatchesOnly: true,
        },
      },
  ];