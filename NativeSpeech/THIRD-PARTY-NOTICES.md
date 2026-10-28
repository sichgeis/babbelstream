# Local Speech Acknowledgements

BabbelStream local speech uses FluidAudio by Fluid Inference (Apache-2.0),
https://github.com/FluidInference/FluidAudio, pinned in NativeSpeech/Package.swift.
The complete upstream license follows in FluidAudio-LICENSE.txt.

Parakeet Ultra by Moondream is a post-trained derivative of NVIDIA
parakeet-tdt-0.6b-v3. Model weights use Creative Commons Attribution 4.0
International (CC-BY-4.0): https://creativecommons.org/licenses/by/4.0/.
Source: https://huggingface.co/moondream/parakeet-ultra.
The downloadable Core ML conversion is provided by Fluid Inference:
https://huggingface.co/FluidInference/parakeet-ultra-coreml.
Changes: conversion/quantization to Core ML by that provider; BabbelStream
verifies the pinned converted bytes without modifying the model weights.
No endorsement by these authors is implied.

The first pilot bundles only the Parakeet runtime. The deferred full build also
uses MLX Audio Swift (MIT), MLX Swift (MIT) and their pinned dependencies;
full-build license/resource inventory must be finalized before distributing it.
Qwen3-ASR and Granite Speech model weights use Apache-2.0 and are not bundled
in the installer. Their downloads remain disabled in the Parakeet pilot.
