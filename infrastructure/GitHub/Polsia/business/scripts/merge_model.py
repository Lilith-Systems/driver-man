#!/usr/bin/env python3
import os
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

def main():
    base_model_id = "Qwen/Qwen2.5-1.5B-Instruct"
    adapter_path = "/home/tehlappy/Desktop/Lilith/checkpoints/lilith_codebase_adapter"
    output_dir = "/home/tehlappy/Desktop/Lilith/merged_model"
    
    print(f"Loading base model: {base_model_id}")
    model = AutoModelForCausalLM.from_pretrained(
        base_model_id,
        torch_dtype=torch.float16,
        device_map="cpu",
        low_cpu_mem_usage=True
    )
    
    print(f"Loading LoRA adapter from: {adapter_path}")
    model = PeftModel.from_pretrained(model, adapter_path)
    
    print("Merging adapter weights with base model...")
    model = model.merge_and_unload()
    
    print(f"Saving merged model to: {output_dir}")
    os.makedirs(output_dir, exist_ok=True)
    model.save_pretrained(output_dir)
    
    print(f"Saving tokenizer to: {output_dir}")
    tokenizer = AutoTokenizer.from_pretrained(adapter_path)
    tokenizer.save_pretrained(output_dir)
    
    print("✓ Model merging completed successfully!")

if __name__ == "__main__":
    main()
