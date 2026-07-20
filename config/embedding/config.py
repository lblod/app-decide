from typing import Optional
from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

embedding_targets = [
  {
    "name": "besluit motivering",
    "filter": """?target a <http://data.europa.eu/eli/ontology#Expression> . 
    ?target <http://data.vlaanderen.be/ns/besluit#motivering> ?motivering .
    FILTER NOT EXISTS {
      ?original <http://purl.org/linguistics/gold/translation> ?target .
    }""",
    "content_path": """?target <http://data.vlaanderen.be/ns/besluit#motivering> ?content .""",
    "embedding_predicate": "http://mu.semte.ch/vocabularies/ext/embeddingVectorMotivering"
  },
  {
    "name": "expressions",
    "filter": """?target a <http://data.europa.eu/eli/ontology#Expression> . 
      FILTER NOT EXISTS {
      ?original <http://purl.org/linguistics/gold/translation> ?target .
    }""",
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

class AppConfig(BaseSettings):
    model_config = SettingsConfigDict(
        env_ignore_empty=True,
    )

    # format: "provider:model", e.g. "ollama:embeddinggemma:300m-qat-q4_0" or "mistral:mistral-embed"

    #embedding_model: "ollama:embeddinggemma:300m-bf16" bigger, but slower
    embedding_model: str = "ollama:embeddinggemma:300m-qat-q4_0"
    #qwen3-embedding:0.6b has a larger context size, but is not recommended by AI advisory board
    embedding_base_url: Optional[str] = "http://embedding-ollama:11434"
    #embedding_base_url: Optional[str] = None
    embedding_api_key: Optional[SecretStr] = None

    max_content_len: int = 2000
    batch_size: int = 2000
    embedding_vector_chunk_size: int = 50
    embedding_graph: str = "http://mu.semte.ch/graphs/public"
    embedding_null: str = "http://mu.semte.ch/vocabularies/ext/embeddingVector/null"
    cron_schedule: str = "* * * * *"
    embed_on_startup: bool = False

config = AppConfig()