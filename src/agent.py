from azure.identity.aio import DefaultAzureCredential

from semantic_kernel.agents.azure_ai import AzureAIAgent
from typing import List, Any, Optional
from azure.identity.aio import DefaultAzureCredential


class Agent:
    def __init__(self, model_deployment_name: str) -> None:
        self.model_deployment_name: str = model_deployment_name
        self.credential: Optional[DefaultAzureCredential] = None
        self.client: Optional[AzureAIAgent] = None

    async def __aenter__(self) -> "Agent":
        self.credential = DefaultAzureCredential()
        self.client = await AzureAIAgent.create_client(credential=self.credential)
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
        model_deployment_name: str,
        name: str,
        instructions: str,
        tools: List[Any]
    ) -> AzureAIAgent:
        agent_definition = await self.client.agents.create_agent(
            model=model_deployment_name,
            name=name,
            instructions=instructions,
            tools=[tool.definitions for tool in tools],
            tool_resources=[tool.resources for tool in tools],
        )
        agent = AzureAIAgent(client=self.client, definition=agent_definition)
        
        return agent