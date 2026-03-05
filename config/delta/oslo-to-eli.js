const TARGETS = [
  "http://lokaal-beslist-consumer/delta",
  "http://decisions-ghent-filter/delta",
  "http://oslo-eli-transformer/delta",
];

export default TARGETS.map((target) => ({
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
    url: target,
  },
  options: {
    resourceFormat: "v0.0.1",
    gracePeriod: 1000,
    ignoreFromSelf: true,
    sendMatchesOnly: true,
  },
}));
