import asyncio
import os

from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.azure_ai_inference import (
    AzureAIInferenceChatPromptExecutionSettings,
    AzureAIInferenceChatCompletion,
)
from semantic_kernel.functions.kernel_arguments import KernelArguments
from semantic_kernel.connectors.ai.function_choice_behavior import (
    FunctionChoiceBehavior,
)
from semantic_kernel.connectors.ai.prompt_execution_settings import (
    PromptExecutionSettings,
)
from semantic_kernel.agents import ChatCompletionAgent

from azure.ai.inference.aio import ChatCompletionsClient
from azure.identity.aio import DefaultAzureCredential
from typing import List, Any, Optional

from semantic_kernel.connectors.search_engine import BingConnector
from plugins.search import SearchService


class Agent:
    def __init__(self, endpoint: str, deployment_name: str) -> None:
        self.deployment_name = deployment_name
        self.endpoint = endpoint

    @staticmethod
    def _create_kernel_with_chat_completion(
        agent_name: str, endpoint: str, deployment_name: str
    ) -> Kernel:
        kernel = Kernel()

        chat_completion_service = AzureAIInferenceChatCompletion(
            service_id=agent_name,
            ai_model_id=deployment_name,
            client=ChatCompletionsClient(
                endpoint=f"{str(endpoint)}/openai/deployments/{deployment_name}",
                credential=DefaultAzureCredential(),
                credential_scopes=["https://cognitiveservices.azure.com/.default"],
            ),
        )

        kernel.add_service(chat_completion_service)

        return kernel

    def create_agent(
        self, agent_name: str, instructions: str, tools: List[Any] = []
    ) -> ChatCompletionAgent:
        kernel = self._create_kernel_with_chat_completion(
            agent_name, self.endpoint, self.deployment_name
        )

        # Add tools to the kernel
        for tool in tools:
            if isinstance(tool, SearchService):
                kernel.add_plugin(tool, plugin_name="search")
            elif isinstance(tool, BingConnector):
                kernel.add_plugin(tool, plugin_name="bing")
            else:
                raise ValueError(f"Unsupported tool type: {type(tool)}")

        # Set up execution settings
        settings = kernel.get_prompt_execution_settings_from_service_id(
            service_id=agent_name
        )
        settings.function_choice_behavior = FunctionChoiceBehavior.Auto()

        agent = ChatCompletionAgent(
            kernel=kernel,
            name=agent_name,
            instructions=instructions,
            arguments=KernelArguments(settings=settings),
        )

        return agent

    def agent_creator(
        self, agent_name: str, rendered_instructions: str, tools: List[Any]
    ) -> ChatCompletionAgent:
        """
        Create an agent using a rendered instruction.

        The instructions parameter is expected to have a 'render' method.
        """
        return self.create_agent(
            agent_name=agent_name,
            instructions=rendered_instructions,
            tools=tools,
        )
