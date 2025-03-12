from semantic_kernel.connectors.ai.open_ai.services.azure_chat_completion import (
    AzureChatCompletion,
)
from semantic_kernel.agents.strategies.termination.kernel_function_termination_strategy import (
    KernelFunctionTerminationStrategy,
)
from semantic_kernel.functions.kernel_function_from_prompt import (
    KernelFunctionFromPrompt,
)
from semantic_kernel.kernel import Kernel
from semantic_kernel.agents.strategies.selection.kernel_function_selection_strategy import (
    KernelFunctionSelectionStrategy,
)
from semantic_kernel.agents.strategies import KernelFunctionSelectionStrategy
from semantic_kernel.agents import AgentGroupChat
from semantic_kernel.connectors.ai.azure_ai_inference import (
    AzureAIInferenceChatCompletion,
)
from semantic_kernel.contents import ChatHistoryTruncationReducer
from jinja2 import Template
from azure.ai.inference.aio import ChatCompletionsClient
from azure.identity.aio import DefaultAzureCredential

import os


class MultiAgent:
    def __init__(
        self,
        endpoint: str,
        deployment_name: str,
        maximum_iterations: int,
        selection_template: Template,
        termination_template: Template,
    ):
        self.endpoint = endpoint
        self.deployment_name = deployment_name
        self.maximum_iterations = maximum_iterations
        self.selection_template = selection_template
        self.termination_template = termination_template

    def create_selection_and_termination_functions(self, agents) -> None:
        self.selection_function = KernelFunctionFromPrompt(
            function_name="selection",
            prompt=self.selection_template.render(
                agents=[agent.name for agent in agents],
                lastmessage=f"{{{{$lastmessage}}}}",
                agent_bing=agents[-1].name,
            ),
        )

        self.termination_function = KernelFunctionFromPrompt(
            function_name="termination",
            prompt=self.termination_template.render(
                lastmessage=f"{{{{$lastmessage}}}}"
            ),
        )

        return self.selection_function, self.termination_function

    @staticmethod
    def _create_kernel_with_chat_completion(
        endpoint: str, deployment_name: str, service_id: str = "planner"
    ) -> Kernel:
        kernel = Kernel()

        chat_completion_service = AzureAIInferenceChatCompletion(
            service_id=service_id,
            ai_model_id=deployment_name,
            client=ChatCompletionsClient(
                endpoint=f"{str(endpoint)}/openai/deployments/{deployment_name}",
                credential=DefaultAzureCredential(),
                credential_scopes=["https://cognitiveservices.azure.com/.default"],
            ),
        )

        kernel.add_service(chat_completion_service)

        return kernel

    def create_chat_group(
        self, agents: list, history_reducer: ChatHistoryTruncationReducer
    ) -> AgentGroupChat:

        kernel = self._create_kernel_with_chat_completion(
            self.endpoint, self.deployment_name
        )

        selection_function, termination_function = (
            self.create_selection_and_termination_functions(agents)
        )

        chat_group = AgentGroupChat(
            agents=agents,
            selection_strategy=KernelFunctionSelectionStrategy(
                function=selection_function,
                kernel=kernel,
                result_parser=lambda result: (
                    str(result.value[0])
                    if result.value is not None
                    else agents[-1].name
                ),
                agent_variable_name="agents",
                history_variable_name="lastmessage",
                history_reducer=history_reducer,
            ),
            termination_strategy=KernelFunctionTerminationStrategy(
                function=termination_function,
                kernel=kernel,
                result_parser=lambda result: str(result.value[0]).lower() == "yes",
                history_variable_name="lastmessage",
                history_reducer=history_reducer,
                maximum_iterations=self.maximum_iterations,
            ),
        )

        return chat_group
