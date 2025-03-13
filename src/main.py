import os
import asyncio
from semantic_kernel.connectors.search_engine import BingConnector
from semantic_kernel.contents import ChatHistoryTruncationReducer

from semantic_kernel.agents import ChatCompletionAgent
from dotenv import load_dotenv
from jinja2 import Environment, FileSystemLoader, Template
from typing import List, Any

# Own modules
from plugins.search import SearchService
from agent import Agent
from multiagent import MultiAgent
from insights_logging import set_up_logging, set_up_tracing, set_up_metrics

load_dotenv(override=True)

# 1. Set up the Azure OpenAI endpoint and deployment name
endpoint = os.environ["AZURE_OPENAI_ENDPOINT"]
deployment_name = os.environ["AZURE_OPENAI_4o_MODEL_NAME"]
search_service_endpoint = os.environ["AZURE_SEARCH_ENDPOINT"]

# 2. Set up the agents
AGENT_SCORE = "Score"
AGENT_DEBT = "Dividas"
AGENT_CC_SANTANDER = "CC_Santander"
AGENT_CC_WILL = "CC_Will"
AGENT_CC_PICPAY = "CC_PicPay"
AGENT_CC_NEON = "CC_Neon"
AGENT_CC_ITAU = "CC_Itau"
AGENT_CC_DM = "CC_DM"
AGENT_CC_DIGIO = "CC_Digio"
AGENT_BING = "BING"

tools = {
    AGENT_SCORE: SearchService(
        service_endpoint=search_service_endpoint, index_name="score"
    ),
    AGENT_DEBT: SearchService(
        service_endpoint=search_service_endpoint, index_name="debt"
    ),
    AGENT_CC_WILL: SearchService(
        service_endpoint=search_service_endpoint, index_name="cartaowill"
    ),
    AGENT_CC_SANTANDER: SearchService(
        service_endpoint=search_service_endpoint, index_name="cartaosantander"
    ),
    AGENT_CC_PICPAY: SearchService(
        service_endpoint=search_service_endpoint, index_name="cartaopicpay"
    ),
    AGENT_CC_NEON: SearchService(
        service_endpoint=search_service_endpoint, index_name="cartaoneon"
    ),
    AGENT_CC_ITAU: SearchService(
        service_endpoint=search_service_endpoint, index_name="cartaoitau"
    ),
    AGENT_CC_DM: SearchService(
        service_endpoint=search_service_endpoint, index_name="cartaodm"
    ),
    AGENT_CC_DIGIO: SearchService(
        service_endpoint=search_service_endpoint, index_name="cartaodigio"
    ),
    AGENT_BING: BingConnector(api_key=os.getenv("AZURE_BING_API_KEY")),
}

# 3. Set up the Agent Creator
agent_creator = Agent(endpoint=endpoint, deployment_name=deployment_name)

# 4. Set up the multi-agent
maximum_iterations = 1

prompts = Environment(loader=FileSystemLoader("./" + os.getenv("TEMPLATE_DIR_PROMPTS")))

selection_template = prompts.get_template("selection.jinja")
termination_template = prompts.get_template("termination.jinja")

multi_agent = MultiAgent(
    endpoint,
    deployment_name,
    maximum_iterations,
    selection_template,
    termination_template,
)

# Set up logging, tracing, and metrics
set_up_logging()
set_up_tracing()
set_up_metrics()


# Initialize the kernel
async def main():

    # 1. Initialize the agents
    instructions = prompts.get_template("instructions.jinja")

    agent_1 = agent_creator.create_agent(
        agent_name=AGENT_SCORE,
        instructions=instructions.render(tool=AGENT_SCORE, type="Azure AI Search"),
        tools=[tools[AGENT_SCORE]],
    )

    agent_2 = agent_creator.create_agent(
        agent_name=AGENT_DEBT,
        instructions=instructions.render(tool=AGENT_DEBT, type="Azure AI Search"),
        tools=[tools[AGENT_DEBT]],
    )

    agent_3 = agent_creator.create_agent(
        agent_name=AGENT_CC_SANTANDER,
        instructions=instructions.render(
            tool=AGENT_CC_SANTANDER, type="Azure AI Search"
        ),
        tools=[tools[AGENT_CC_SANTANDER]],
    )

    agent_4 = agent_creator.create_agent(
        agent_name=AGENT_CC_WILL,
        instructions=instructions.render(tool=AGENT_CC_WILL, type="Azure AI Search"),
        tools=[tools[AGENT_CC_WILL]],
    )

    agent_5 = agent_creator.create_agent(
        agent_name=AGENT_CC_PICPAY,
        instructions=instructions.render(tool=AGENT_CC_PICPAY, type="Azure AI Search"),
        tools=[tools[AGENT_CC_PICPAY]],
    )

    agent_6 = agent_creator.create_agent(
        agent_name=AGENT_CC_NEON,
        instructions=instructions.render(tool=AGENT_CC_NEON, type="Azure AI Search"),
        tools=[tools[AGENT_CC_NEON]],
    )

    agent_7 = agent_creator.create_agent(
        agent_name=AGENT_CC_ITAU,
        instructions=instructions.render(tool=AGENT_CC_ITAU, type="Azure AI Search"),
        tools=[tools[AGENT_CC_ITAU]],
    )

    agent_8 = agent_creator.create_agent(
        agent_name=AGENT_CC_DM,
        instructions=instructions.render(tool=AGENT_CC_DM, type="Azure AI Search"),
        tools=[tools[AGENT_CC_DM]],
    )

    agent_9 = agent_creator.create_agent(
        agent_name=AGENT_CC_DIGIO,
        instructions=instructions.render(tool=AGENT_CC_DIGIO, type="Azure AI Search"),
        tools=[tools[AGENT_CC_DIGIO]],
    )

    agent_10 = agent_creator.create_agent(
        agent_name=AGENT_BING,
        instructions=instructions.render(tool=AGENT_BING, type="Bing Search"),
        tools=[tools[AGENT_BING]],
    )

    # 2. Create the agent group
    agents = [
        agent_1,
        agent_2,
        agent_3,
        agent_4,
        agent_5,
        agent_6,
        agent_7,
        agent_8,
        agent_9,
        agent_10,
    ]

    history_reducer = ChatHistoryTruncationReducer(target_count=5)
    group_chat = multi_agent.create_chat_group(
        agents=agents, history_reducer=history_reducer
    )

    # 3. Add the task as a message to the group chat
    for user_input in USER_INPUTS:
        await group_chat.add_chat_message(message=user_input)

        async for content in group_chat.invoke():
            print(f"# {content.name}: {content.content}")


if __name__ == "__main__":
    USER_INPUTS = [
        "O que é o Feirão Serasa Limpa Nome e como ele funciona?",
        "Quais são os descontos de até 99% oferecidos pelo Feirão Serasa Limpa Nome?",
        "Como posso consultar meu CPF pelo site da Serasa?",
        "O que é e como funciona o Carrinho de Ofertas para organizar dívidas?",
        "Quais são os principais benefícios de negociar suas dívidas com a Serasa?",
        "Como confirmar se um canal é oficial do Serasa Limpa Nome?",
        "Quais as formas de pagamento disponíveis para as negociações no Feirão?",
        "Como posso realizar um atendimento presencial para quitar minha dívida?",
        "Quais vantagens posso obter utilizando o aplicativo Serasa Limpa Nome?",
        "Como funcionam as condições de parcelamento conforme o orçamento oferecidas pela Serasa?",
        "Quais são os benefícios do Cartão Will, especialmente sem tarifa e sem anuidade?",
        "Como posso solicitar o Cartão Will através da plataforma do Serasa Crédito?",
        "O Cartão Will oferece cashback; como funciona esse benefício?",
        "Quais facilidades o Cartão Will proporciona na recarga de celular e no acompanhamento dos gastos?",
        "Existe algum processo 100% digital para solicitar o Cartão Will?",
        "O Cartão Will possui alguma taxa ou anuidade oculta?",
        "Quais são as principais diferenças entre o Cartão Santander Free e os outros cartões Santander?",
        "O que torna o Cartão Santander Elite Platinum especial em termos de benefícios?",
        "Como o app do Santander permite acompanhar os gastos e controlar o limite do cartão?",
        "O que é o Santander AAdvantage Platinum e como ele possibilita o acúmulo de milhas?",
        "Como posso solicitar um cartão de crédito Santander através da plataforma do Serasa Crédito?",
        "Quais benefícios são oferecidos pelo Cartão Santander Unique?",
        "Quais são os benefícios do Cartão PicPay, como anuidade zero e cashback?",
        "Como funciona a solicitação do Cartão PicPay pelo Serasa Crédito?",
        "O Cartão PicPay permite parcelar o Pix; como essa funcionalidade opera?",
        "Quais são as diferenças entre o PicPay Card Gold, Platinum e Black?",
        "Que opções o Cartão PicPay oferece para compras online e para a conta digital?",
        "Quais são as principais vantagens do Cartão Neon em comparação com outros cartões de crédito?",
        "Como funciona o mecanismo de cashback e o limite elástico do Cartão Neon?",
        "Posso solicitar o Cartão Neon através do Serasa Crédito? Qual o processo?",
        "Quais benefícios adicionais, como o programa Vai de Visa, o Cartão Neon oferece?",
        "De que forma o Cartão Neon ajuda no gerenciamento de despesas e na confirmação de limites?",
        "Quais são os principais benefícios dos cartões Itaucard oferecidos pelo Itaú?",
        "Como funciona o Itaucard Click Platinum e quais são os seus beneficios?",
        "O que o Azul Itaucard oferece em termos de acúmulo de pontos e descontos em passagens?",
        "Como o Latam PASS Itaucard beneficia os clientes com descontos e acúmulo de milhas?",
        "Quais vantagens os cartões de crédito Itaú para supermercados (Extra e Pão de Açúcar) proporcionam?",
        "Como posso solicitar um cartão de crédito Itaú através do Serasa Crédito?",
        "Quais são os diferenciais do DMcard Mastercard®, como o código de segurança dinâmico?",
        "Como funciona o pagamento por aproximação no cartão DMcard?",
        "Quais recompensas são oferecidas pelo programa Mastercard Surpreenda do DMcard?",
        "Qual é o valor da anuidade do DMcard e como ela é cobrada?",
        "Quais são os benefícios exclusivos do cartão Digio, como o Pix parcelado e o cashback?",
        "Como o cartão Digio possibilita compras nacionais e internacionais sem anuidade?",
        "O que é o Programa de Pontos Livelo do Digio e como posso acumular pontos?",
        "Como posso gerenciar a fatura do cartão Digio pelo aplicativo?",
        "Quais são as condições para solicitar o cartão Digio pelo Serasa Crédito?",
        "O cartão Digio oferece conversão de moeda para compras internacionais? Quais são as taxas aplicadas?",
        "O que é o Serasa Score e como ele influencia a obtenção de crédito?",
        "Como posso melhorar meu Serasa Score conectando minhas contas e pagando dívidas via Pix?",
    ]
    asyncio.run(main())
