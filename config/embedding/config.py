embedding_targets = [
  {
    "filter": """?target a <http://data.europa.eu/eli/ontology#Expression> .""",
    "content_path": """?target <https://data.europarl.europa.eu/def/epvoc#expressionContent> ?content .""",
    "embedding_predicate": "http://mu.semte.ch/vocabularies/ext/embeddingVector"
  },
  {
    "filter": """?target a  <https://schema.oparl.org/Organization> .""",
    "content_path": """
      {
        {
          ?target <https://schema.oparl.org/organizationType> ?content .
          BIND(0 as ?index)
        }
        UNION
        {
          ?target <https://schema.oparl.org/name> ?content .
          BIND(1 as ?index)
        }
        UNION
        {
          ?target <https://schema.oparl.org/shortName> ?content .
          BIND(2 as ?index)
        }
        UNION
        {
          ?target <https://schema.oparl.org/body> / <https://schema.oparl.org/name> ?content .
          BIND(3 as ?index)
        }
      }
  """,
  "embedding_predicate": "http://mu.semte.ch/vocabularies/ext/embeddingVector"
  }
]

batch_size = 100
embedding_vector_chunk_size = 50
embedding_graph = "http://mu.semte.ch/graphs/public"
embedding_null = "http://mu.semte.ch/vocabularies/ext/embeddingVector/null"
#embedding_model = "embeddinggemma:300m-bf16" bigger, but slower
embedding_model = "embeddinggemma:300m-qat-q4_0"
#qwen3-embedding:0.6b has a larger context size, but is not recommended by AI advisory board
cron_schedule = "* * * * *" # every 5 minutes