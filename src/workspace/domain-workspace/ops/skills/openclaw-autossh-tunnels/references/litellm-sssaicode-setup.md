# OpenCode + SSSAiCode 配置指南 (LiteLLM 统一代理)

使用 **LiteLLM** 作为单一代理，支持 GPT-5.2、GPT-5-Codex 和 Claude (Opus/Sonnet)。

---

## 架构

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────────────────┐
│  OpenCode   │─────▶│  LiteLLM     │─────▶│  SSSAiCode                  │
│  (本地)      │      │  :4000       │      │  (根据模型路由到不同端点)      │
└─────────────┘      └──────────────┘      ├─────────────────────────────┤
                                           │ node-hk: gpt-5.2/mini       │
                                           │ codex:   gpt-5-codex        │
                                           │ claude:  opus/sonnet        │
                                           └─────────────────────────────┘
```

---

## 关键配置

### 1. LiteLLM 配置

**文件**: `~/.openclaw/workspace/litellm/config.yaml`

```yaml
server:
  port: 4000
  host: 127.0.0.1

model_list:
  # node-hk endpoint
  - model_name: gpt-5.2
    litellm_params:
      model: openai/gpt-5.2
      api_base: https://node-hk.sssaicode.com/api/v1
      api_key: os.environ/SSSAICODE_API_KEY

  - model_name: gpt-5.2-mini
    litellm_params:
      model: openai/gpt-5.2-mini
      api_base: https://node-hk.sssaicode.com/api/v1
      api_key: os.environ/SSSAICODE_API_KEY

  # codex endpoint (注意: 有 /v1 后缀)
  - model_name: gpt-5-codex
    litellm_params:
      model: openai/gpt-5-codex
      api_base: https://codex.sssaicode.com/api/v1
      api_key: os.environ/SSSAICODE_API_KEY

  # claude endpoint (注意: 无 /v1 后缀，使用 anthropic/ 前缀)
  - model_name: claude-opus-4-6
    litellm_params:
      model: anthropic/claude-opus-4-6
      api_base: https://claude.sssaicode.com/api
      api_key: os.environ/SSSAICODE_API_KEY

  - model_name: claude-sonnet-4-5-20250929
    litellm_params:
      model: anthropic/claude-sonnet-4-5-20250929
      api_base: https://claude.sssaicode.com/api
      api_key: os.environ/SSSAICODE_API_KEY

litellm_settings:
  drop_params: true
  callbacks: custom_callbacks.proxy_handler_instance
```

**回调文件**: `~/.openclaw/workspace/litellm/custom_callbacks.py`

```python
from litellm.integrations.custom_logger import CustomLogger

class SSSCallback(CustomLogger):
    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        data.pop("max_output_tokens", None)
        data.pop("max_tokens", None)
        if isinstance(data.get("input"), str):
            data["input"] = [{"role": "user", "content": data["input"]}]
        return data

proxy_handler_instance = SSSCallback()
```

### 2. OpenCode 配置

**文件**: `~/.config/opencode/opencode.json`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "sss/gpt-5.2",
  "small_model": "sss/gpt-5.2-mini",
  "provider": {
    "sss": {
      "npm": "@ai-sdk/openai",
      "name": "SSSAiCode",
      "options": {
        "baseURL": "http://127.0.0.1:4000",
        "apiKey": "{env:SSSAICODE_API_KEY}"
      },
      "models": {
        "gpt-5.2": { "name": "GPT 5.2" },
        "gpt-5.2-mini": { "name": "GPT 5.2 Mini" },
        "gpt-5-codex": { "name": "GPT 5 Codex" }
      }
    },
    "sssclaude": {
      "npm": "@ai-sdk/anthropic",
      "name": "SSSAiCode Claude",
      "options": {
        "baseURL": "http://127.0.0.1:4000",
        "apiKey": "{env:SSSAICODE_API_KEY}"
      },
      "models": {
        "claude-opus-4-6": { "name": "Claude Opus 4.6" },
        "claude-sonnet-4-5-20250929": { "name": "Claude Sonnet 4.5" }
      }
    }
  }
}
```

---

## 使用

### 1. 启动代理

```bash
~/.openclaw/workspace/scripts/litellm-sss-start.sh
```

### 2. 运行 OpenCode

```bash
# GPT-5.2
opencode run --model sss/gpt-5.2 "你的指令"

# GPT-5 Codex
opencode run --model sss/gpt-5-codex "写个快排"

# Claude Opus 4.6 ✅ 可用
opencode run --model sssclaude/claude-opus-4-6 "分析这段代码"

# Claude Sonnet 4.5 ✅ 可用
opencode run --model sssclaude/claude-sonnet-4-5-20250929 "解释这个概念"
```

---

## 端点说明

| 端点 | 用途 | 模型格式 | URL 格式 |
|------|------|----------|----------|
| `node-hk.sssaicode.com` | GPT-5.2 系列 | OpenAI | `/api/v1` |
| `codex.sssaicode.com` | GPT-5 Codex | OpenAI | `/api/v1` |
| `claude.sssaicode.com` | Claude 系列 | Anthropic | `/api` (无 v1) |

---

## 故障排查

### "模型不支持"
- 确认使用的是 LiteLLM 代理，不是直连
- 检查模型名是否与 config.yaml 中定义的 `model_name` 一致

### 404 错误
- Claude 端点没有 `/v1` 后缀
- 检查 `api_base` 配置是否正确

### 认证失败
```bash
# 检查环境变量
echo $SSSAICODE_API_KEY

# 确保 ~/.env 已加载
source ~/.env
```

---

## 文件清单

| 文件 | 用途 |
|------|------|
| `~/.openclaw/workspace/litellm/config.yaml` | LiteLLM 主配置 |
| `~/.openclaw/workspace/litellm/custom_callbacks.py` | 参数清洗回调 |
| `~/.openclaw/workspace/scripts/litellm-sss-start.sh` | 启动脚本 |
| `~/.config/opencode/opencode.json` | OpenCode 配置 |
