from semantic_kernel.functions import kernel_function
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from azure.search.documents import SearchClient
from azure.search.documents.models import (
    QueryAnswerType,
    QueryCaptionType,
    QueryType,
    VectorizableTextQuery,
)
import os
from typing import TypedDict
import logging
from typing import Annotated


class SearchModel(TypedDict):
    search_query: Annotated[str, "The query used to search in the Azure search index."]


class SearchService:
    """
    Description: Query an Azure AI search index using a search query.
    """

    def __init__(self, service_endpoint: str, index_name: str) -> None:
        credential = DefaultAzureCredential(
            managed_identity_client_id=os.getenv("AZURE_CLIENT_ID")
        )
        self.search_client = SearchClient(
            endpoint=service_endpoint, index_name=index_name, credential=credential
        )

    def _format_azure_search_results(self, results: list, truncate: int = 2000) -> str:
        formatted_results = []

        for result in results:
            # Access all properties like a dictionary
            chunk_id = result["chunk_id"] if "chunk_id" in result else "N/A"
            reranker_score = (
                result["@search.reranker_score"]
                if "@search.reranker_score" in result
                else "N/A"
            )
            source_doc_path = result["title"] if "title" in result else "N/A"
            content = result["chunk"] if "chunk" in result else "N/A"

            # Truncate content to specified number of characters
            content = content[:truncate] + "..." if len(content) > truncate else content

            # Extract caption (highlighted caption if available)
            captions = (
                result["@search.captions"] if "@search.captions" in result else []
            )
            caption = "Caption not available"
            if captions:
                first_caption = captions[0]
                if first_caption.highlights:
                    caption = first_caption.highlights
                elif first_caption.text:
                    caption = first_caption.text

            # Format each result section
            result_string = (
                f"========================================\n"
                f"🆔 ID: {chunk_id}\n"
                f"📂 Source Doc Title: {source_doc_path}\n"
                f"📜 Content: {content}\n"
                f"💡 Caption: {caption}\n"
                f"========================================"
            )

            formatted_results.append(result_string)

        # Join all the formatted results into a single string
        return "\n\n".join(formatted_results)

    @kernel_function(
        name="query_index",
        description="Uses the Azure search index to search for documents",
    )
    def query_index(self, context: SearchModel) -> str:
        """Query the index using the provided search query."""
        logging.info(
            f"Querying Azure Search index with search query: {context['search_query']}"
        )
        try:
            search_query = context["search_query"]
            # generate a vector representation of the search query
            vector_query = VectorizableTextQuery(
                text=search_query, k_nearest_neighbors=50, fields="text_vector"
            )

            results = self.search_client.search(
                search_text=search_query,
                vector_queries=[vector_query],
                query_type=QueryType.SEMANTIC,
                semantic_configuration_name="default",
                query_caption=QueryCaptionType.EXTRACTIVE,
                query_answer=QueryAnswerType.EXTRACTIVE,
                top=5,
            )

            logging.info(f"Results: {results}")
        except Exception as e:
            logging.info(f"Error: {e}")
            return f"Error: {e}"

        return self._format_azure_search_results(results, truncate=2000)
