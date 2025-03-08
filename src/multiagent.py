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


class MultiAgent:
    def __init__(
        self,
        deployment_name: str,
        maximum_iterations: int,
        selection_template: str,
        termination_template: str,
    ):
        self.deployment_name = deployment_name
        self.maximum_iterations = maximum_iterations
        self.selection_function = KernelFunctionFromPrompt(
            function_name="selection",
            prompt=selection_template,
        )
        self.termination_function = KernelFunctionFromPrompt(
            function_name="termination",
            prompt=termination_template,
        )

    @staticmethod
    def _create_kernel_with_chat_completion(
        service_id: str, deployment_name: str
    ) -> Kernel:
        kernel = Kernel()
        kernel.add_service(
            AzureChatCompletion(service_id=service_id, deployment_name=deployment_name)
        )
        return kernel

    def create_chat_group(self, agents: list):
        chat_group = AgentGroupChat(
            agents=agents,
            selection_strategy=KernelFunctionSelectionStrategy(
                function=self.selection_function,
                kernel=self._create_kernel_with_chat_completion(
                    "selection", self.deployment_name
                ),
                result_parser=lambda result: (
                    str(result.value[0])
                    if result.value is not None
                    else agents[-1].name
                ),
                agent_variable_name="agents",
                history_variable_name="history",
            ),
            termination_strategy=KernelFunctionTerminationStrategy(
                function=self.termination_function,
                kernel=self._create_kernel_with_chat_completion(
                    "termination", self.deployment_name
                ),
                result_parser=lambda result: str(result.value[0]).lower() == "yes",
                history_variable_name="history",
                maximum_iterations=self.maximum_iterations,
            ),
        )
        return chat_group
