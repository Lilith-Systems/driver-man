#!/usr/bin/env python3
"""QLoRA fine-tune Qwen2.5-1.5B on MSN/Cyberpunk mod corpus."""
import os
import torch

os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"

from datasets import load_dataset
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from peft import LoraConfig, prepare_model_for_kbit_training
from trl import SFTTrainer, SFTConfig

DATASET = "/home/tehlappy/Desktop/Lilith/data/msn_cyberpunk_dataset.json"
OUTPUT_DIR = "/home/tehlappy/Desktop/Lilith/checkpoints/msn_cyberpunk"
ADAPTER = f"{OUTPUT_DIR}/msn_cyberpunk_adapter"
BASE = "Qwen/Qwen2.5-1.5B-Instruct"
MAX_STEPS = int(os.getenv("MSN_TRAIN_STEPS", "150"))


def main():
    if not os.path.isfile(DATASET):
        raise SystemExit(f"Dataset missing: {DATASET}\nRun: python scripts/codegen_cyberpunk.py")

    print(f"Loading {BASE} (4-bit QLoRA, RTX 3060 safe)")
    tokenizer = AutoTokenizer.from_pretrained(BASE)
    tokenizer.pad_token = tokenizer.eos_token

    bnb = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.float16,
    )
    # RTX 3060: leave headroom when CP2077/ollama share VRAM
    max_mem = os.getenv("MSN_TRAIN_GPU_MB", "2800")
    model = AutoModelForCausalLM.from_pretrained(
        BASE,
        quantization_config=bnb,
        device_map="auto",
        max_memory={0: f"{max_mem}MiB", "cpu": "24GiB"},
        torch_dtype=torch.float16,
        low_cpu_mem_usage=True,
    )
    model = prepare_model_for_kbit_training(model, use_gradient_checkpointing=True)

    peft = LoraConfig(
        r=16,
        lora_alpha=32,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_dropout=0.1,
        bias="none",
        task_type="CAUSAL_LM",
    )

    def fmt(example):
        conv = example["conversations"]
        msgs = [
            {"role": "user", "content": conv[0]["value"]},
            {"role": "assistant", "content": conv[1]["value"]},
        ]
        return tokenizer.apply_chat_template(msgs, tokenize=False)

    ds = load_dataset("json", data_files=DATASET, split="train")
    print(f"Training on {len(ds)} MSN/Cyberpunk entries, max_steps={MAX_STEPS}")

    args = SFTConfig(
        output_dir=OUTPUT_DIR,
        per_device_train_batch_size=1,
        gradient_accumulation_steps=16,
        learning_rate=2e-4,
        logging_steps=5,
        max_steps=MAX_STEPS,
        bf16=True,
        fp16=False,
        optim="paged_adamw_8bit",
        save_strategy="steps",
        save_steps=50,
        warmup_ratio=0.03,
        report_to="none",
        max_length=int(os.getenv("MSN_TRAIN_MAX_LEN", "1024")),
        gradient_checkpointing=True,
    )

    trainer = SFTTrainer(
        model=model,
        train_dataset=ds,
        peft_config=peft,
        processing_class=tokenizer,
        formatting_func=fmt,
        args=args,
    )

    print("Starting MSN Cyberpunk QLoRA training...")
    trainer.train()
    trainer.model.save_pretrained(ADAPTER)
    tokenizer.save_pretrained(ADAPTER)
    print(f"Adapter saved: {ADAPTER}")


if __name__ == "__main__":
    main()