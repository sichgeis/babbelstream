// Pinned public model metadata. No runtime catalog lookup or automatic update.
let localModelCatalogJSON = #"""
[
  {
    "id": "parakeetUltra",
    "repository": "FluidInference/parakeet-ultra-coreml",
    "revision": "95eaa59a39d4394f047a4dc5cce480388a60d1b6",
    "files": [
      {
        "path": "Decoder.mlmodelc/analytics/coremldata.bin",
        "bytes": 243,
        "sha256": "fe92b6cfaa012abd5248c0bc877832f19807015abffc60d87b8ccc8ccb48b3b5"
      },
      {
        "path": "Decoder.mlmodelc/coremldata.bin",
        "bytes": 560,
        "sha256": "3b06e66768f0df7e21795f50e2b29300e33eeb1a2579dc42c695279c2d308497"
      },
      {
        "path": "Decoder.mlmodelc/model.mil",
        "bytes": 13110,
        "sha256": "956f600207f88396017ca5c96cfa3acd5bfee60835a5b44b762e033a8fb28955"
      },
      {
        "path": "Decoder.mlmodelc/weights/weight.bin",
        "bytes": 23604992,
        "sha256": "02a0d219f281b9665bc10c8768649403b2eebbbf4b44c627041d948e0de11bb4"
      },
      {
        "path": "Encoder.mlmodelc/analytics/coremldata.bin",
        "bytes": 243,
        "sha256": "d87101d824d6723cf95304da33755c3c60e762663b9ef2b0c4bd0aa166a09a0d"
      },
      {
        "path": "Encoder.mlmodelc/coremldata.bin",
        "bytes": 514,
        "sha256": "397a84a4062f563cbc5f56077c674f09a61d85be5090f61d2f1932afb92ac0fe"
      },
      {
        "path": "Encoder.mlmodelc/model.mil",
        "bytes": 1002653,
        "sha256": "f5d601568a4171d99a314c0fe3f6bc67715da2623732a3fb566e050ea83e5848"
      },
      {
        "path": "Encoder.mlmodelc/weights/weight.bin",
        "bytes": 594211328,
        "sha256": "315ba01f33cadbf601d43ac7f5c86208b7aa75fdaa34705c9869d5abe3521c9b"
      },
      {
        "path": "JointDecisionv3.mlmodelc/analytics/coremldata.bin",
        "bytes": 243,
        "sha256": "68d38ca646aebafa7a9329e2efda50f5767c49e89fdb5f77f212072bb66f97c4"
      },
      {
        "path": "JointDecisionv3.mlmodelc/coremldata.bin",
        "bytes": 592,
        "sha256": "5e3af5a4ce686f6c237cadbd9284e10d333bc0e1546633cd0e430e6194044bc4"
      },
      {
        "path": "JointDecisionv3.mlmodelc/model.mil",
        "bytes": 11777,
        "sha256": "791b3c3cf3eb2079c84623fc880f6bba008d1366e5f8b03e9a8ed8bd4d7194a0"
      },
      {
        "path": "JointDecisionv3.mlmodelc/weights/weight.bin",
        "bytes": 12642764,
        "sha256": "3f310b85b82341c53ec383025ab094a4e462ee1c592e1ad7c6bfe39cff66ca25"
      },
      {
        "path": "Preprocessor.mlmodelc/analytics/coremldata.bin",
        "bytes": 243,
        "sha256": "c9beeb989c8d66f8be11df59bc6df277ec76cee404f6865b46243835ef562f6d"
      },
      {
        "path": "Preprocessor.mlmodelc/coremldata.bin",
        "bytes": 486,
        "sha256": "dbde3f2300842c1fd51ef3ff948a0bcffe65ffd2dca10707f2509f32c1d65b1d"
      },
      {
        "path": "Preprocessor.mlmodelc/metadata.json",
        "bytes": 2841,
        "sha256": "2a98699e22d279dd37fa1d238aeb1c6db1df0d6fad687775324157689d8f3acf"
      },
      {
        "path": "Preprocessor.mlmodelc/model.mil",
        "bytes": 28181,
        "sha256": "4b8518a956450fec57f06c2a21bdffc26973f7f1fa6842fb38fe917f896b6b93"
      },
      {
        "path": "Preprocessor.mlmodelc/weights/weight.bin",
        "bytes": 491072,
        "sha256": "129b76e3aeafa8afa3ea76d995b964b145fe83700d579f6ff42c4c38fa0968ea"
      },
      {
        "path": "parakeet_vocab.json",
        "bytes": 151122,
        "sha256": "7ec60e05f1b24480736ec0eed40900f4626bce1fa9a60fd700ec7e2a59198735"
      }
    ]
  },
  {
    "id": "qwen3ASR",
    "repository": "mlx-community/Qwen3-ASR-1.7B-8bit",
    "revision": "a8379a2e2f9e313c9292cdf1af4055ab56d50d55",
    "files": [
      {
        "path": "chat_template.json",
        "bytes": 1161,
        "sha256": "75a8cfca24f00de72d796fbfed6858fc9614ef3dabd8696684cc3bc03a9c58ff"
      },
      {
        "path": "config.json",
        "bytes": 7188,
        "sha256": "1b76b3b6c655fc54595da025f7a96474ad9fa86363303fbdd61a7d8483ccfaf7"
      },
      {
        "path": "generation_config.json",
        "bytes": 142,
        "sha256": "1da527824d81e07118facff437e03f2e24a23311e3bdeb2368973fe77e5f275c"
      },
      {
        "path": "merges.txt",
        "bytes": 1671853,
        "sha256": "8831e4f1a044471340f7c0a83d7bd71306a5b867e95fd870f74d0c5308a904d5"
      },
      {
        "path": "model.safetensors",
        "bytes": 2463307541,
        "sha256": "bf304b009cc7eca79283056f787b44c952d24ac22cec787b39732bba3c23c13c"
      },
      {
        "path": "model.safetensors.index.json",
        "bytes": 78968,
        "sha256": "0a5d0ec11188602242ff81a9969883d0fdeb98cd5d85cd1413089d897c201af5"
      },
      {
        "path": "preprocessor_config.json",
        "bytes": 330,
        "sha256": "45e120a4eda2c20c5d7f2ea9354e63536bf35e27aa573fb7cdf78017b378770d"
      },
      {
        "path": "tokenizer_config.json",
        "bytes": 12487,
        "sha256": "4942d005604266809309cabc9f4e9cb89ce855d59b14681fdc0e1cc62ea26c4c"
      },
      {
        "path": "vocab.json",
        "bytes": 2776833,
        "sha256": "ca10d7e9fb3ed18575dd1e277a2579c16d108e32f27439684afa0e10b1440910"
      }
    ]
  },
  {
    "id": "graniteSpeech",
    "repository": "ibm-granite/granite-speech-5.0-2b",
    "revision": "c684620bb54fc89d14ba27256b23bbc9e09ba764",
    "files": [
      {
        "path": "added_tokens.json",
        "bytes": 26,
        "sha256": "b4956ad3505e979f2f25cc2e2be2163d8e23730f854b6c5a14ed106f3dd90549"
      },
      {
        "path": "chat_template.jinja",
        "bytes": 193,
        "sha256": "e3219da52634178f68696475ea4518ade9d1b5c9a71b825f28312b73afc432c0"
      },
      {
        "path": "config.json",
        "bytes": 2281,
        "sha256": "14e35a6daa1b4bdd38b3fc0b62eaf519e8993a2fbbbc2b527432c684376d62a3"
      },
      {
        "path": "generation_config.json",
        "bytes": 147,
        "sha256": "4a5e80bbcf4116a96b385e0af3ff94b03a7393d424a1201cb1f974e9ffc2e1da"
      },
      {
        "path": "merges.txt",
        "bytes": 916646,
        "sha256": "b6fe424e334903f7fb84d3a106d9730455f4744b9fe3c21ee136d97a00e72502"
      },
      {
        "path": "model.safetensors",
        "bytes": 4626528224,
        "sha256": "4151269881d2dd825d45ca75d6552b2a20e6e39d0934ed84c4db826af8bf6d88"
      },
      {
        "path": "out_llm.safetensors",
        "bytes": 411447460,
        "sha256": "a6b638a913b2dcf835dfbc621d9780d2557ac635a5c4718d1ffe64d39beb8ada"
      },
      {
        "path": "preprocessor_config.json",
        "bytes": 336,
        "sha256": "382a6f26300937721969b01909c96c2e519620b6781f7b45cb8b2e348a932d87"
      },
      {
        "path": "processor_config.json",
        "bytes": 80,
        "sha256": "13edc723022827cc3620ba2e2b4bcf52287b365d77e60a31227f0a4b7dea5f9c"
      },
      {
        "path": "special_tokens_map.json",
        "bytes": 579,
        "sha256": "c08676c49fd7969a3130f72be6d4bf34da66aa484a6e21dffe359893a1bd5f2e"
      },
      {
        "path": "tokenizer.json",
        "bytes": 7153607,
        "sha256": "43ca88fd0519c64ef93fa0a90cbc4e560fe485b5ba60348a86bc3c624f37918e"
      },
      {
        "path": "tokenizer_config.json",
        "bytes": 17882,
        "sha256": "de233c19cd9efa63738f7481f318fc2048060f751ac9fd7957b131c43226b403"
      },
      {
        "path": "vocab.json",
        "bytes": 1612704,
        "sha256": "8af71076de8b0b626eed0f4c984faf0a7c062479164b2a31308a948524d4f69c"
      }
    ]
  }
]
"""#
