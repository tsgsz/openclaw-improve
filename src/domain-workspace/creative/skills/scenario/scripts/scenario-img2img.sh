#!/bin/bash
# Scenario Image-to-Image 快捷脚本
# 用法: scenario-img2img.sh "prompt" input.png [output.png] [strength] [model]

set -e

PROMPT="$1"
INPUT="$2"
OUTPUT="${3:-output.png}"
STRENGTH="${4:-0.75}"
MODEL="${5:-flux.1-dev}"

if [ -z "$PROMPT" ] || [ -z "$INPUT" ]; then
  echo "用法: scenario-img2img.sh \"prompt\" input.png [output.png] [strength] [model]"
  echo ""
  echo "参数:"
  echo "  prompt   - 图片描述"
  echo "  input    - 输入图片（本地路径或 URL）"
  echo "  output   - 输出文件名（默认 output.png）"
  echo "  strength - 变化强度 0-1（默认 0.75，越高变化越大）"
  echo "  model    - 模型 ID（默认 flux.1-dev）"
  exit 1
fi

API_KEY="${SCENARIO_API_KEY:-}"
API_SECRET="${SCENARIO_API_SECRET:-}"

if [ -z "$API_KEY" ] || [ -z "$API_SECRET" ]; then
  echo "错误: 请设置 SCENARIO_API_KEY 和 SCENARIO_API_SECRET 环境变量"
  exit 1
fi

# 检查输入是 URL 还是本地文件
if [[ "$INPUT" == http* ]]; then
  echo "🎨 图生图: $PROMPT"
  echo "   来源: URL"
  echo "   模型: $MODEL, 强度: $STRENGTH"
  
  PAYLOAD="{
    \"prompt\": \"$PROMPT\",
    \"imageUrl\": \"$INPUT\",
    \"strength\": $STRENGTH,
    \"modelId\": \"$MODEL\",
    \"numSamples\": 1,
    \"guidance\": 3.5,
    \"numInferenceSteps\": 28
  }"
else
  # 本地文件需要先上传
  echo "📤 上传图片: $INPUT"
  
  # 获取上传 URL
  UPLOAD_RESPONSE=$(curl -s -X POST \
    -u "$API_KEY:$API_SECRET" \
    -H "Content-Type: application/json" \
    -d '{"contentType": "image/png"}' \
    https://api.cloud.scenario.com/v1/assets/upload)
  
  UPLOAD_URL=$(echo "$UPLOAD_RESPONSE" | jq -r '.uploadUrl')
  ASSET_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.assetId')
  
  if [ "$UPLOAD_URL" = "null" ]; then
    echo "❌ 获取上传 URL 失败: $UPLOAD_RESPONSE"
    exit 1
  fi
  
  # 上传图片
  curl -s -X PUT \
    -H "Content-Type: image/png" \
    --data-binary "@$INPUT" \
    "$UPLOAD_URL"
  
  echo "   Asset ID: $ASSET_ID"
  echo "🎨 图生图: $PROMPT"
  echo "   模型: $MODEL, 强度: $STRENGTH"
  
  PAYLOAD="{
    \"prompt\": \"$PROMPT\",
    \"image\": \"$ASSET_ID\",
    \"strength\": $STRENGTH,
    \"modelId\": \"$MODEL\",
    \"numSamples\": 1,
    \"guidance\": 3.5,
    \"numInferenceSteps\": 28
  }"
fi

RESPONSE=$(curl -s -X POST \
  -u "$API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  https://api.cloud.scenario.com/v1/generate/img2img)

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
    RESULT_ASSET_ID=$(echo "$JOB_RESPONSE" | jq -r '.job.metadata.assetIds[0]')
    
    # 获取下载 URL
    ASSET_RESPONSE=$(curl -s -u "$API_KEY:$API_SECRET" \
      "https://api.cloud.scenario.com/v1/assets/$RESULT_ASSET_ID")
    IMAGE_URL=$(echo "$ASSET_RESPONSE" | jq -r '.asset.url')
    
    # 下载图片
    curl -s "$IMAGE_URL" -o "$OUTPUT"
    echo "✅ 保存到: $OUTPUT"
    echo "   Asset ID: $RESULT_ASSET_ID"
    exit 0
  elif [ "$STATUS" = "failure" ] || [ "$STATUS" = "canceled" ]; then
    echo "❌ 生成失败: $STATUS"
    exit 1
  fi
  
  echo "   状态: $STATUS ($PROGRESS%, ${WAITED}s)"
  sleep 3
  WAITED=$((WAITED + 3))
done

echo "❌ 超时"
exit 1
