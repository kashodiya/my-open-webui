


## Copy prompt from promptden.com
copy($$('.leading-7')[0].innerText)



cd checkpoints/
wget https://civitai.com/api/download/models/128713
mv 128713 dreamshaper_8.safetensors
loras
https://civitai.com/api/download/models/14856
mv 14856 MoXinV1.safetensors
wget https://civitai.com/api/download/models/32988
mv 32988 blindbox_v1_mix.safetensors



embedding_example
cd checkpoints/
wget https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.safetensors




gligen_textbox_example
cd gligen
wget https://huggingface.co/comfyanonymous/GLIGEN_pruned_safetensors/resolve/main/gligen_sd14_textbox_pruned.safetensors



Inpaining
checkpoint
wget https://huggingface.co/stabilityai/stable-diffusion-2-inpainting/resolve/main/512-inpainting-ema.safetensors



cd ~/projects/comfy/ComfyUI/models/checkpoints/
wget https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors
wget https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev-fp8.safetensors
wget https://huggingface.co/Comfy-Org/stable-diffusion-3.5-fp8/resolve/main/sd3.5_large_fp8_scaled.safetensors




## area_composition_square_area_for_subject
cd vae
wget https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors
cd checkpoints/
wget https://huggingface.co/admruul/anything-v3.0/resolve/main/Anything-V3.0.ckpt



## text_to_video_wan
vae
https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors

cd text_encoders/
wget https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

cd diffusion_models/
wget https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_1.3B_fp16.safetensors





## latent_upscale_different_prompt_model.json

https://huggingface.co/waifu-diffusion/wd-1-5-beta3/resolve/main/wd-illusion-fp16.safetensors
https://huggingface.co/jomcs/NeverEnding_Dream-Feb19-2023/resolve/07c9bc67d4ac9a85b68321d9b62f20c00171d8d5/CarDos%20Anime/cardosAnime_v10.safetensors





Workflow for pencil art: https://openart.ai/workflows/norsizu/photos-to-manga-style/3CTEJ480CyJ6QNruEcvy

cd projects/comfy/ComfyUI/models/checkpoints/
wget https://huggingface.co/Linaqruf/animagine-xl/resolve/main/animagine-xl.safetensors

cd projects/comfy/ComfyUI/models/controlnet
https://huggingface.co/lllyasviel/sd_control_collection/resolve/d1b278d0d1103a3a7c4f7c2c327d236b082a75b1/diffusers_xl_depth_full.safetensors

cd projects/comfy/ComfyUI/models/loras/
wget https://huggingface.co/datasets/sjidnd/LIb_damoxing/resolve/main/%E6%89%8B%E9%83%A8%E4%BC%98%E5%8C%96_V0.9_v0.9.safetensors






Workflow pencil-2: https://openart.ai/workflows/datou/creative-sticker/vk8EMXJPzYuzQhEJlr7z

cd projects/comfy/ComfyUI/models/checkpoints/
wget https://huggingface.co/lllyasviel/flux1_dev/resolve/main/flux1-dev-fp8.safetensors

cd projects/comfy/ComfyUI/models/loras/
wget https://huggingface.co/Shakker-Labs/FLUX.1-dev-LoRA-One-Click-Creative-Template/resolve/main/FLUX-dev-lora-One-Click-Creative-Template.safetensors
wget https://huggingface.co/ByteDance/Hyper-SD/resolve/main/Hyper-FLUX.1-dev-8steps-lora.safetensors

cd ~/projects/comfy/ComfyUI/models/pulid

wget https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.1.safetensors

cd ~/projects/comfy/ComfyUI/models/loras
wget https://huggingface.co/thwri/CogFlorence-2.2-Large/resolve/main/model.safetensors -O CogFlorence-2.2-Large.safetensors

wget https://huggingface.co/thwri/CogFlorence-2.2-Large/resolve/main/model.safetensors






cd projects/comfy/ComfyUI/models/checkpoints/
wget https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.safetensors
cd ..
cd upscale_models/
git clone https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth
cd ../checkpoints/
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
wget https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors






## Upscale image to image
https://github.com/greenzorro/comfyui-workflow-upscaler?tab=readme-ov-file

cd upscale_models/
wget https://huggingface.co/philz1337x/upscaler/resolve/main/4x-UltraSharp.pth
cd ..
cd controlnet/
wget https://huggingface.co/TheMistoAI/MistoLine/resolve/main/mistoLine_rank256.safetensors
cd ../checkpoints/
wget https://huggingface.co/Lykon/dreamshaper-xl-lightning/resolve/main/DreamShaperXL_Lightning.safetensors
cd ..
cd embeddings/
wget https://civitai.com/api/download/models/134583
cd ..
cd loras/
wget https://civitai.com/api/download/models/135867
mv 135867 add-detail-xl.safetensors




https://openart.ai/workflows/mastiff-infantile-29/creative-upscale/dp0uHUJAFAo1w9MR58WJ

cd checkpoints/
wget https://huggingface.co/liamhvn/epiCPhotoGasm-ultimate-fidelity/resolve/407c438df9b04f018715566025d694182a1f1c3d/epicphotogasm_ultimateFidelity.safetensors

cd ../lorss
wget https://huggingface.co/yungplin/More_details/resolve/main/more_details.safetensors
wget https://huggingface.co/philz1337x/loras/resolve/main/SDXLrender_v2.0.safetensors

cd ../upscale_models/
wget https://huggingface.co/pengxian/upscale_models/resolve/main/4xNomosUniDAT_otf.pth
wget https://huggingface.co/lllyasviel/control_v11f1e_sd15_tile/resolve/main/diffusion_pytorch_model.bin -O control_v11f1e_sd15_tile.bin