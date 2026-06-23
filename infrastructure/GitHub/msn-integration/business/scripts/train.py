#!/usr/bin/env python3
import os
import json
import torch
os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"
from datasets import load_dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig
)
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from trl import SFTTrainer, SFTConfig

def main():
    model_id = "Qwen/Qwen2.5-1.5B-Instruct"
    dataset_path = "/home/tehlappy/Desktop/Lilith/data/codebase_dataset.json"
    output_dir = "/home/tehlappy/Desktop/Lilith/checkpoints"
    
    print(f"Loading tokenizer and model: {model_id}")
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    tokenizer.pad_token = tokenizer.eos_token
    
    # 4-bit Quantization configuration for 6GB VRAM safety
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.float16
    )
    
    model = AutoModelForCausalLM.from_pretrained(
        model_id,
        quantization_config=bnb_config,
        device_map={"": 0},
        torch_dtype=torch.float16,
        low_cpu_mem_usage=True
    )
    
    # Prepare model for PEFT
    model = prepare_model_for_kbit_training(model)
    
    # LoRA Configuration
    peft_config = LoraConfig(
        r=16,
        lora_alpha=32,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_dropout=0.1,
        bias="none",
        task_type="CAUSAL_LM"
    )
    
    # model wrapping handled automatically by SFTTrainer using peft_config
    
    # Load and format the codebase SFT dataset
    print(f"Loading dataset from {dataset_path}...")
    
    def formatting_prompts_func(example):
        conv = example['conversations']
        messages = [
            {"role": "user", "content": conv[0]["value"]},
            {"role": "assistant", "content": conv[1]["value"]}
        ]
        return tokenizer.apply_chat_template(messages, tokenize=False)

    dataset = load_dataset("json", data_files=dataset_path, split="train")
    
    # Fine-tuning hyperparameters optimized for RTX 3060 (6GB VRAM)
    training_args = SFTConfig(
        output_dir=output_dir,
        per_device_train_batch_size=1,
        gradient_accumulation_steps=16,
        learning_rate=2e-4,
        logging_steps=5,
        max_steps=200,          # Adjust steps based on your convergence needs
        bf16=True,
        fp16=False,
        optim="paged_adamw_8bit", # Critical for avoiding VRAM OOMs
        save_strategy="steps",
        save_steps=50,
        warmup_ratio=0.03,
        report_to="none",
        max_length=2048
    )
    
    trainer = SFTTrainer(
        model=model,
        train_dataset=dataset,
        peft_config=peft_config,
        processing_class=tokenizer,
        formatting_func=formatting_prompts_func,
        args=training_args,
    )
    
    print("Starting QLoRA codebase training...")
    trainer.train()
    
    # Save the learned adapters
    adapter_path = os.path.join(output_dir, "lilith_codebase_adapter")
    trainer.model.save_pretrained(adapter_path)
    tokenizer.save_pretrained(adapter_path)
    print(f"✓ LoRA adapter saved to: {adapter_path}")

if __name__ == "__main__":
    main()
