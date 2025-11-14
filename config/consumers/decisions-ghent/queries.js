import { INGEST_GRAPH } from "./config";

const prefixes = {
  rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  mu: "http://mu.semte.ch/vocabularies/core/",
  besluit: "http://data.vlaanderen.be/ns/besluit#",
  dcterms: "http://purl.org/dc/terms/",
  prov: "http://www.w3.org/ns/prov#",
  mandaat: "http://data.vlaanderen.be/ns/mandaat#",
};

const bestuursorganen = [
  "http://data.lblod.info/id/bestuursorganen/6efc9b0c3ebb3371031d45e517d88f66eb115adf28e5e1827684522f56a8aa2",
  "http://data.lblod.info/id/bestuursorganen/c126b20bc1a94de293b7fceaf998c82e9a7a1d56ba34cbf9992aa4bf01ae2b0",
  "http://data.lblod.info/id/bestuursorganen/c55fc5e892d9540e8d2463b4377e1f4b2caad04b280118f9fc408e5df61f573",
  "http://data.lblod.info/id/bestuursorganen/304b1cf175214a830ab2000c5f38fd688524e34d33a0fda4466693378aef8a4",
  "http://data.lblod.info/id/bestuursorganen/325c479023eed57b44ecdc40bb1c1b1b42a213975ca01f5a127bee6e9a4e798",
  "http://data.lblod.info/id/bestuursorganen/cc2aba212d4102c6fa9ee2d43f27a1cde04da144a21cb8b1683dc7bb1e0154d",
  "http://data.lblod.info/id/bestuursorganen/d06e5e292522046e94ebd6560813604df8e467a7347efc46c8b066ab5bbd38b",
  "http://data.lblod.info/id/bestuursorganen/807a46610dcbd3c0646ea9d13784d09ba0bb2f6de6cd7c9029e3dc9a15ad33a",
  "http://data.lblod.info/id/bestuursorganen/c484767ea88b545af011c47b52ac540a0ffdab400cfe9d3f53c6685ec8733cc",
  "http://data.lblod.info/id/bestuursorganen/0c0338929c4edb5e847f98481c1df2b22ffa858b44e49dec603d3d97cf6272c",
  "http://data.lblod.info/id/bestuursorganen/0d0c1eeff199e9f0d9aabfa7e68b0600d6092fff099c5d7a0caba3d8ef762fb",
  "http://data.lblod.info/id/bestuursorganen/192502e559e9b150c6bf895e3c145b7cf80feb286c48182ccf25153192d4365",
  "http://data.lblod.info/id/bestuursorganen/e1bdfec06e5407566b72ea6a1a9e89c82a1d5a81d1461772761e0974b2ddebe",
  "http://data.lblod.info/id/bestuursorganen/16d7f193d9f7f49c27a16978b2cb800c2ae06a8bd64a0532c4dd47aae83a2b6",
  "http://data.lblod.info/id/bestuursorganen/196d3dc10bb71196ea971bb5ff315083742e9a458d97b51bc31e2320b8d9de7",
  "http://data.lblod.info/id/bestuursorganen/a315ccc212dc2e19db45209761f5786e125138d01815a8f339092b70778b18e",
  "http://data.lblod.info/id/bestuursorganen/3ee975c24dddc132d37c262cac268012335575cf3ea2c0fa274d5b75f9c8ecd",
  "http://data.lblod.info/id/bestuursorganen/c0cf2d8f3a45a50e65b34dab2059dbdab19d716e66f35f9a06e23b975d8d46e",
  "http://data.lblod.info/id/bestuursorganen/20825ff7b875937c78d5520a1de2c29339ededf65c8a5c4fc9b257604769a3e",
  "http://data.lblod.info/id/bestuursorganen/1e9960d4c38937637027f21226ad19ff443e7bd33b8f6cc1a9cd47cc34f6fc5",
];

const queryDefs = {
  Agendapunt: {
    type: "besluit:Agendapunt",
    properties: [
      "http://data.vlaanderen.be/ns/besluit#aangebrachtNa",
      "http://data.vlaanderen.be/ns/besluit#Agendapunt.type",
      "http://data.vlaanderen.be/ns/besluit#geplandOpenbaar",
      "http://data.vlaanderen.be/ns/besluit#noopener",
      "http://data.vlaanderen.be/ns/besluit#noreferrer",
      "http://purl.org/dc/terms/#description",
      "http://purl.org/dc/terms/#isPartOf",
      "http://purl.org/dc/terms/#title",
      "http://purl.org/dc/terms/description",
      "http://purl.org/dc/terms/title",
      "http://www.w3.org/ns/prov#wasDerivedFrom",
    ],
    bestuursorgaanPropertyPath: "^besluit:behandelt / besluit:isGehoudenDoor",
  },
  BehandelingVanAgendapunt: {
    type: "besluit:BehandelingVanAgendapunt",
    properties: [
      "http://data.europa.eu/eli/ontology#description",
      "http://data.europa.eu/eli/ontology#title",
      "http://data.vlaanderen.be/ns/besluit#citeeropschrift",
      "http://data.vlaanderen.be/ns/besluit#gebeurtNa",
      "http://data.vlaanderen.be/ns/besluit#heeftAanwezige",
      "http://data.vlaanderen.be/ns/besluit#heeftSecretaris",
      "http://data.vlaanderen.be/ns/besluit#heeftStemming",
      "http://data.vlaanderen.be/ns/besluit#heeftVoorzitter",
      "http://data.vlaanderen.be/ns/besluit#isGehoudenDoor",
      "http://data.vlaanderen.be/ns/besluit#openbaar",
      "http://mu.semte.ch/vocabularies/ext/aanwezigenTable",
      "http://mu.semte.ch/vocabularies/ext/heeftAfwezigeBijAgendapunt",
      "http://mu.semte.ch/vocabularies/ext/stemmingTable",
      "http://purl.org/dc/terms/subject",
      "http://purl.org/dc/terms/title",
      "http://www.w3.org/ns/prov#generated",
      "http://www.w3.org/ns/prov#wasDerivedFrom",
    ],
    bestuursorgaanPropertyPath:
      "dcterms:subject / ^besluit:behandelt / besluit:isGehoudenDoor",
  },
  Besluit: {
    type: "besluit:Besluit",
    properties: [
      "http://data.europa.eu/eli/ontology#date_publication",
      "http://data.europa.eu/eli/ontology#description",
      "http://data.europa.eu/eli/ontology#has_part",
      "http://data.europa.eu/eli/ontology#language",
      "http://data.europa.eu/eli/ontology#passed_by",
      "http://data.europa.eu/eli/ontology#related_to",
      "http://data.europa.eu/eli/ontology#title",
      "http://data.europa.eu/eli/ontology#title_short",
      "http://data.vlaanderen.be/ns/besluit#motivering",
      "http://data.vlaanderen.be/ns/besluit#noopener",
      "http://data.vlaanderen.be/ns/besluit#noreferrer",
      "http://lblod.data.gift/vocabularies/besluit/authenticityType",
      "http://lblod.data.gift/vocabularies/besluit/chartOfAccount",
      "http://lblod.data.gift/vocabularies/besluit/extractedDecisionContent",
      "http://lblod.data.gift/vocabularies/besluit/hasAdditionalTaxRate",
      "http://www.w3.org/ns/prov#value",
      "http://www.w3.org/ns/prov#wasDerivedFrom",
      "http://www.w3.org/ns/prov#wasGeneratedBy",
    ],
    bestuursorgaanPropertyPath:
      "^prov:generated / dcterms:subject / ^besluit:behandelt / besluit:isGehoudenDoor",
  },
  Bestuursorgaan: {
    type: "besluit:Bestuursorgaan",
    properties: [
      "http://data.vlaanderen.be/ns/besluit#classificatie",
      "http://data.vlaanderen.be/ns/mandaat#isTijdspecialisatieVan",
      "http://www.w3.org/2004/02/skos/core#prefLabel",
      "http://www.w3.org/ns/prov#wasDerivedFrom>",
    ],
    bestuursorgaanPropertyPath: "",
  },
  Mandataris: {
    type: "mandaat:Mandataris",
    properties: [
      "http://data.vlaanderen.be/ns/mandaat#isBestuurlijkeAliasVan",
      "http://www.w3.org/ns/prov#wasDerivedFrom",
      "http://xmlns.com/foaf/0.1/familyName",
      "https://data.vlaanderen.be/ns/persoon#gebruikteVoornaam",
    ],
    bestuursorgaanPropertyPath:
      "^besluit:heeftVoorzitter / dcterms:subject / ^besluit:behandelt / besluit:isGehoudenDoor",
  },
  Stemming: {
    type: "besluit:Stemming",
    properties: [
      "http://data.vlaanderen.be/ns/besluit#aantalOnthouders",
      "http://data.vlaanderen.be/ns/besluit#aantalTegenstanders",
      "http://data.vlaanderen.be/ns/besluit#aantalVoorstanders",
      "http://data.vlaanderen.be/ns/besluit#geheim",
      "http://data.vlaanderen.be/ns/besluit#gevolg",
      "http://data.vlaanderen.be/ns/besluit#heeftAanwezige",
      "http://data.vlaanderen.be/ns/besluit#heeftOnthouder",
      "http://data.vlaanderen.be/ns/besluit#heeftStemmer",
      "http://data.vlaanderen.be/ns/besluit#heeftTegenstander",
      "http://data.vlaanderen.be/ns/besluit#heeftVoorstander",
      "http://data.vlaanderen.be/ns/besluit#onderwerp",
      "http://www.w3.org/ns/prov#wasDerivedFrom",
    ],
    bestuursorgaanPropertyPath:
      "^besluit:heeftStemming / dcterms:subject / ^besluit:behandelt / besluit:isGehoudenDoor",
  },
};

const buildPrefixBlock = () =>
  Object.entries(prefixes)
    .map(([prefix, uri]) => `PREFIX ${prefix}: <${uri}>`)
    .join("\n");

const buildValuesBlock = (varName) => {
  const lines = bestuursorganen
    .map((bestuursorgaan) => `<${bestuursorgaan}>`)
    .join("\n");
  return `VALUES ${varName} {\n${lines}\n}`;
};

const buildQuery = (queryType, graph) => {
  const s = "?s";
  const prefixBlock = buildPrefixBlock();

  const header = `  ${s} a ${queryType.type} ;
     rdf:type ?type ;
     mu:uuid ?uuid .`;

  const optionals = (queryType.properties || [])
    .map((p, i) => `OPTIONAL { ${s} <${p}> ?p${i + 1} . }`)
    .join("\n");

  const path = queryType.bestuursorgaanPropertyPath || "";
  const pathBlock = path.length
    ? `  ${s} ${path} ?bestuursorgaan .\n${buildValuesBlock("?bestuursorgaan")}`
    : `${buildValuesBlock(s)}`;

  const innerBody = `
${header}
${optionals ? optionals + "\n" : ""}${pathBlock}
`.trim();

  const graphWrapped = graph
    ? `GRAPH <${graph}> {\n${innerBody}\n}`
    : innerBody;

  return `
${prefixBlock}

SELECT *
WHERE {
${graphWrapped}
}`.trim();
};

export const queries = {
  get agendapunt() {
    return buildQuery(queryDefs.Agendapunt, INGEST_GRAPH);
  },
  get behandelingVanAgendapunt() {
    return buildQuery(queryDefs.BehandelingVanAgendapunt, INGEST_GRAPH);
  },
  get besluit() {
    return buildQuery(queryDefs.Besluit, INGEST_GRAPH);
  },
  get bestuursorgaan() {
    return buildQuery(queryDefs.Bestuursorgaan, INGEST_GRAPH);
  },
  get mandataris() {
    return buildQuery(queryDefs.Mandataris, INGEST_GRAPH);
  },
  get stemming() {
    return buildQuery(queryDefs.Stemming, INGEST_GRAPH);
  },
};
