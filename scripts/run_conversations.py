import asyncio
import sys
import os

# add main to path
current_dir = os.path.dirname(os.path.abspath(__file__))
root_path = os.path.abspath(os.path.join(current_dir, '../'))
sys.path.insert(0, root_path)

from main import main
from config.user_inputs import USER_INPUTS

def input_generator(conversation: list):
    for user_input in conversation:
        if user_input["role"] == "user":
            yield user_input["content"]
    yield "exit"

async def run_all_conversations():
    for idx, conversation in enumerate(USER_INPUTS):
        print(f"\n--- Starting conversation {idx + 1} ---")
        _gen = input_generator(conversation)
        __builtins__.input = lambda prompt="": next(_gen)
        await main()
        print(f"--- Conversation {idx + 1} ended ---\n")

if __name__ == "__main__":
    asyncio.run(run_all_conversations())