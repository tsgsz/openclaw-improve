---
name: scenario
description: 使用 Scenario API 生成和修改图片。支持 text-to-image、image-to-image、背景移除、图片增强等功能。用于需要 AI 生图或修图时。
---

> 运行说明：本技能为执行型技能，按当前 Runner 架构使用。

# 场景生成 API

Scenario 是一个 AI 图片生成和编辑平台，提供 text-to-image、image-to-image、ControlNet、Inpaint、Upscale 等功能。

**官方文档**: https://docs.scenario.com

## 配置

**API Key** 从环境变量读取:
```bash
export SCENARIO_API_KEY="YOUR_API_KEY"
export SCENARIO_API_SECRET="YOUR_API_SECRET"
```

获取 API Key: https://app.scenario.com/settings/api

**Base URL**: `https://api.cloud.scenario.com/v1`

所有请求使用 HTTP Basic Auth: `api_key:api_secret`

---

## 可用模型

### 🍌 Nano Banana 系列（Gemini）
| 模型 ID | 说明 | 推荐场景 |
|---------|------|----------|
| `model_google-gemini-pro-image-t2i` | **Nano Banana Pro (Gemini 3.0 Pro)** | 最强大，支持推理+搜索+14图参考 |
| `model_google-gemini-flash-image-t2i` | Nano Banana (Gemini 2.5 Flash) | 快速生成，性价比高 |

### Flux 系列
| 模型 ID | 说明 | 推荐场景 |
|---------|------|----------|
| `flux.1-dev` | Flux Dev（默认推荐） | 通用高质量生成 |
| `flux.1-schnell` | Flux Schnell | 快速生成，质量略低 |
| `flux.1-pro` | Flux Pro | 商业级质量 |

### 其他模型
| 模型 ID | 说明 |
|---------|------|
| `sd-xl-1.0` | Stable Diffusion XL |
| `seedream-4` | Seedream 4 |
| `gpt-image` | GPT Image |

### 特殊模型
| 模型 ID | 说明 |
|---------|------|
| `model_sc-upscale-flux` | Flux 图片放大（2-8x） |
| `model_upscale-v3` | SDXL 快速放大（1-16x） |
| `model_sc-upscale-flux-texture` | 纹理增强放大 |

### 查询可用模型
```bash
curl -u "$API_KEY:$API_SECRET" \
  https://api.cloud.scenario.com/v1/models
```

---

## 1. Text-to-Image (文字生图)

**端点**: `POST /v1/generate/txt2img`

### 完整参数
| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| prompt | string | ✅ | - | 图片描述 |
| modelId | string | ✅ | - | 模型 ID |
| negativePrompt | string | ❌ | - | 负面提示词（SD 模型可用，Flux 不支持） |
| numSamples | int | ❌ | 1 | 生成数量（1-4） |
| guidance | float | ❌ | 7.5 | 引导强度（1-20） |
| numInferenceSteps | int | ❌ | 30 | 推理步数（越高越精细，越慢） |
| width | int | ❌ | 512 | 宽度（256-1536，步长 64） |
| height | int | ❌ | 512 | 高度（256-1536，步长 64） |
| scheduler | string | ❌ | EulerAncestralDiscrete | 采样器 |
| seed | int | ❌ | 随机 | 随机种子（相同种子 = 相同结果） |

### 示例
```bash
curl -X POST \
  -u "$API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a futuristic city at sunset, highly detailed, cyberpunk style",
    "modelId": "flux.1-dev",
    "numSamples": 1,
    "guidance": 3.5,
    "numInferenceSteps": 28,
    "width": 1024,
    "height": 1024,
    "seed": 42
  }' \
  https://api.cloud.scenario.com/v1/generate/txt2img
```

---

## 2. Image-to-Image (图生图)

**端点**: `POST /v1/generate/img2img`

### 额外参数
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| imageUrl | string | 二选一 | 参考图片 URL |
| image | string | 二选一 | 参考图片 asset ID |
| strength | float | ❌ | 变化强度（0-1，默认 0.8，越高变化越大） |

### 示例
```bash
curl -X POST \
  -u "$API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "transform to anime style",
    "imageUrl": "https://example.com/photo.jpg",
    "modelId": "flux.1-dev",
    "strength": 0.75,
    "guidance": 3.5,
    "numInferenceSteps": 28
  }' \
  https://api.cloud.scenario.com/v1/generate/img2img
```

---

## 3. ControlNet (精细控制)

**端点**: `POST /v1/generate/controlnet`

### 可用 Modality（控制类型）
| Modality | 说明 | 用途 |
|----------|------|------|
| `canny` | 边缘检测 | 保持轮廓、线条 |
| `pose` | 姿态检测 | 保持人物姿势 |
| `depth` | 深度图 | 保持空间层次 |
| `seg` | 语义分割 | 精确区域控制 |
| `sketch` | 草图 | 手绘转渲染 |
| `scribble` | 涂鸦 | 简笔画引导 |
| `blur` | 去模糊 | 增强清晰度 |
| `tile` | 平铺 | 高分辨率细节 |
| `gray` | 上色 | 黑白转彩色 |
| `low-quality` | 增强 | 低质量转高质量 |
| `illusion` | 幻觉 | 抽象/超现实 |

### 参数
| 参数 | 类型 | 说明 |
|------|------|------|
| controlImage | string | 控制图片（data URL） |
| controlImageId | string | 控制图片 asset ID |
| modality | string | 控制类型（如 `pose:0.5`，0.5 是强度） |

### 示例
```bash
curl -X POST \
  -u "$API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a superhero in a dynamic pose, comic book style",
    "controlImageId": "asset_xxx",
    "modality": "pose:0.5",
    "modelId": "flux.1-dev",
    "guidance": 3.5,
    "numInferenceSteps": 28
  }' \
  https://api.cloud.scenario.com/v1/generate/controlnet
```

---

## 4. Inpaint (局部重绘)

**端点**: `POST /v1/generate/inpaint`

### 参数
| 参数 | 类型 | 说明 |
|------|------|------|
| image | string | 原图 asset ID |
| mask | string | 蒙版（白色区域将被重绘） |
| prompt | string | 重绘内容描述 |

### 示例
```bash
curl -X POST \
  -u "$API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a beautiful garden",
    "image": "asset_original",
    "mask": "asset_mask",
    "modelId": "flux.1-dev",
    "guidance": 3.5,
    "numInferenceSteps": 28
  }' \
  https://api.cloud.scenario.com/v1/generate/inpaint
```

---

## 5. Upscale (图片放大)

**端点**: `POST /v1/generate/custom/{modelId}`

### 模型选择
| 模型 | 放大倍数 | 特点 |
|------|----------|------|
| `model_sc-upscale-flux` | 2-8x | 高质量，支持 LoRA |
| `model_upscale-v3` | 1-16x | 快速，成本低 |
| `model_sc-upscale-flux-texture` | 2-8x | 纹理增强 |

### 参数
| 参数 | 类型 | 说明 |
|------|------|------|
| image | string | 原图 asset ID |
| upscaleFactor | int | 放大倍数 |
| preset | string | `precise` / `balanced` / `creative` |
| prompt | string | 可选，引导放大风格 |
| detailsEnable | bool | 增强细节 |

### 示例
```bash
curl -X POST \
  -u "$API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "asset_xxx",
    "upscaleFactor": 4,
    "preset": "balanced",
    "detailsEnable": true
  }' \
  https://api.cloud.scenario.com/v1/generate/custom/model_sc-upscale-flux
```

---

## 6. 上传图片

在使用 img2img/inpaint 前，需要先上传本地图片。

```bash
# 1. 获取上传 URL
curl -X POST \
  -u "$API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"contentType": "image/png"}' \
  https://api.cloud.scenario.com/v1/assets/upload

# 响应: {"uploadUrl": "...", "assetId": "asset_xxx"}

# 2. PUT 上传图片
curl -X PUT \
  -H "Content-Type: image/png" \
  --data-binary "@local_image.png" \
  "$UPLOAD_URL"
```

---

## 7. 轮询任务状态

所有生成都是异步的，需要轮询获取结果。

```bash
JOB_ID="job_xxx"

# 轮询直到 status = "success"
curl -u "$API_KEY:$API_SECRET" \
  https://api.cloud.scenario.com/v1/jobs/$JOB_ID
```

**状态值**: `queued` → `running` → `success` / `failure`

---

## 8. 下载生成的图片

```bash
ASSET_ID="asset_xxx"

# 获取图片信息（包含 URL）
curl -u "$API_KEY:$API_SECRET" \
  https://api.cloud.scenario.com/v1/assets/$ASSET_ID

# 直接下载
curl -u "$API_KEY:$API_SECRET" \
  "https://api.cloud.scenario.com/v1/assets/$ASSET_ID/download" \
  -o output.png
```

---

## 快捷脚本

### scenario-txt2img.sh
```bash
# 用法: scenario-txt2img.sh "prompt" [output.png] [model] [width] [height]
~/.openclaw/workspace/skill-catalog/project/scenario/scripts/scenario-txt2img.sh \
  "a cute cat in space" \
  cat.png \
  flux.1-dev \
  1024 \
  1024
```

### scenario-img2img.sh
```bash
# 用法: scenario-img2img.sh "prompt" input.png [output.png] [strength] [model]
~/.openclaw/workspace/skill-catalog/project/scenario/scripts/scenario-img2img.sh \
  "make it cyberpunk" \
  photo.png \
  output.png \
  0.7 \
  flux.1-dev
```

---

## 价格

- 按生成次数/复杂度计费
- 响应中的 `creativeUnitsCost` 显示消耗的 credit
- 详见 https://scenario.com/pricing

## 注意事项

1. 生成是异步的，需要轮询 job 状态
2. 大尺寸图片消耗更多 credits
3. numInferenceSteps 越高质量越好但越慢
4. Flux 模型不支持 negativePrompt
5. 保存 assetId 以便后续操作
