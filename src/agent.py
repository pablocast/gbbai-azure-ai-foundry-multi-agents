from azure.identity.aio import DefaultAzureCredential

from semantic_kernel.agents.azure_ai import AzureAIAgent, AzureAIAgentSettings
from typing import List, Any, Optional
from azure.identity.aio import DefaultAzureCredential
import asyncio

class Agent:
    def __init__(self, deployment_name: str, connection_string: str) -> None:
        self.deployment_name = deployment_name
        self.connection_string = connection_string

    async def __aenter__(self) -> "Agent":
        self.ai_agent_settings = AzureAIAgentSettings.create(model_deployment_name=self.deployment_name)
        self.credential = DefaultAzureCredential()
        self.client = AzureAIAgent.create_client(
            credential=self.credential,
            conn_str=self.connection_string,
        )
        return self

    async def __aexit__(
        self, 
        exc_type: Optional[type], 
        exc_val: Optional[BaseException], 
        exc_tb: Optional[Any]
    ) -> None:
        await self.credential.close()
        await self.client.close()

    async def create_agent(
        self,
        name: str,
        instructions: str,
        tool: dict[str, Any],
    ) -> AzureAIAgent:
        agent_definition = await self.client.agents.create_agent(
            model=self.ai_agent_settings.model_deployment_name,
            name=name,
            instructions=instructions,
            tools=tool["definitions"],
            tool_resources=tool["resources"],
        )
        return AzureAIAgent(client=self.client, definition=agent_definition)

