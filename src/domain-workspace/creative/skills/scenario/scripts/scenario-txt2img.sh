#!/bin/bash
# Scenario Text-to-Image 快捷脚本
# 用法: scenario-txt2img.sh "prompt" [output.png] [model] [width] [height] [steps] [guidance] [seed]

set -e

PROMPT="$1"
OUTPUT="${2:-output.png}"
MODEL="${3:-flux.1-dev}"
WIDTH="${4:-1024}"
HEIGHT="${5:-1024}"
STEPS="${6:-28}"
GUIDANCE="${7:-3.5}"
SEED="${8:-}"

if [ -z "$PROMPT" ]; then
  echo "用法: scenario-txt2img.sh \"prompt\" [output.png] [model] [width] [height] [steps] [guidance] [seed]"
  echo ""
  echo "可用模型:"
  echo "  model_google-gemini-pro-image-t2i  - 🍌 Nano Banana Pro (Gemini 3.0 Pro) 推荐"
  echo "  model_google-gemini-flash-image-t2i - 🍌 Nano Banana (Gemini 2.5 Flash)"
  echo "  flux.1-dev      - Flux Dev（默认）"
  echo "  flux.1-schnell  - Flux Schnell（快速）"
  echo "  flux.1-pro      - Flux Pro（商业级）"
  echo "  sd-xl-1.0       - Stable Diffusion XL"
  exit 1
fi

API_KEY="${SCENARIO_API_KEY:-}"
API_SECRET="${SCENARIO_API_SECRET:-}"

if [ -z "$API_KEY" ] || [ -z "$API_SECRET" ]; then
  echo "错误: 请设置 SCENARIO_API_KEY 和 SCENARIO_API_SECRET 环境变量"
  exit 1
fi

echo "🎨 生成中: $PROMPT"
echo "   模型: $MODEL"
echo "   尺寸: ${WIDTH}x${HEIGHT}"
echo "   步数: $STEPS, 引导: $GUIDANCE"

# 构建 payload
if [ -n "$SEED" ]; then
  SEED_JSON=", \"seed\": $SEED"
else
  SEED_JSON=""
fi

PAYLOAD="{
  \"prompt\": \"$PROMPT\",
  \"modelId\": \"$MODEL\",
  \"numSamples\": 1,
  \"guidance\": $GUIDANCE,
  \"numInferenceSteps\": $STEPS,
  \"width\": $WIDTH,
  \"height\": $HEIGHT
  $SEED_JSON
}"

# 发起生成
RESPONSE=$(curl -s -X POST \
  -u "$API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  https://api.cloud.scenario.com/v1/generate/txt2img)

JOB_ID=$(echo "$RESPONSE" | jq -r '.job.jobId')
COST=$(echo "$RESPONSE" | jq -r '.creativeUnitsCost // "N/A"')

if [ "$JOB_ID" = "null" ] || [ -z "$JOB_ID" ]; then
  echo "❌ 生成失败: $RESPONSE"
  exit 1
fi

echo "⏳ Job ID: $JOB_ID (消耗: $COST credits)"

# 轮询等待完成
MAX_WAIT=180
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
  JOB_RESPONSE=$(curl -s -u "$API_KEY:$API_SECRET" \
    https://api.cloud.scenario.com/v1/jobs/$JOB_ID)
  STATUS=$(echo "$JOB_RESPONSE" | jq -r '.job.status')
  PROGRESS=$(echo "$JOB_RESPONSE" | jq -r '.job.progress // 0')
  
  if [ "$STATUS" = "success" ]; then
    ASSET_ID=$(echo "$JOB_RESPONSE" | jq -r '.job.metadata.assetIds[0]')
    
    # 获取下载 URL
    ASSET_RESPONSE=$(curl -s -u "$API_KEY:$API_SECRET" \
      "https://api.cloud.scenario.com/v1/assets/$ASSET_ID")
    IMAGE_URL=$(echo "$ASSET_RESPONSE" | jq -r '.asset.url')
    
    # 下载图片
    curl -s "$IMAGE_URL" -o "$OUTPUT"
    echo "✅ 保存到: $OUTPUT"
    echo "   Asset ID: $ASSET_ID"
    exit 0
  elif [ "$STATUS" = "failure" ] || [ "$STATUS" = "canceled" ]; then
    echo "❌ 生成失败: $STATUS"
    echo "$JOB_RESPONSE" | jq '.job.error // .job'
    exit 1
  fi
  
  echo "   状态: $STATUS ($PROGRESS%, ${WAITED}s)"
  sleep 3
  WAITED=$((WAITED + 3))
done

echo "❌ 超时: 生成耗时超过 ${MAX_WAIT}s"
exit 1
