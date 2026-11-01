#!/usr/bin/env bash
# fugui.skill 一键安装脚本
# 用法: curl -fsSL <raw-url>/install.sh | bash
# 效果: 把 fugui/ 技能目录装到本机已存在的 Agent skills 目录（zcode / claude / codex）
set -euo pipefail

REPO_RAW="${FUGUI_REPO_RAW:-https://raw.githubusercontent.com/ZMKC404/fugui/main}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "⬇️  下载 fugui.skill ..."
mkdir -p "$TMP/fugui"
curl -fsSL "$REPO_RAW/fugui/SKILL.md" -o "$TMP/fugui/SKILL.md"
# references 与 assets 按文件清单下载
for f in diagnose translate position strategy convert ai-workflow style-voice; do
  mkdir -p "$TMP/fugui/references"
  curl -fsSL "$REPO_RAW/fugui/references/$f.md" -o "$TMP/fugui/references/$f.md" || echo "  (跳过 references/$f.md)"
done
for f in "内容自检表" "情绪锚点画布"; do
  mkdir -p "$TMP/fugui/assets"
  curl -fsSL "$REPO_RAW/fugui/assets/$f.md" -o "$TMP/fugui/assets/$f.md" || echo "  (跳过 assets/$f.md)"
done

if ! grep -q "^name: fugui" "$TMP/fugui/SKILL.md" 2>/dev/null; then
  echo "❌ 下载的 SKILL.md 校验失败，安装中止"; exit 1
fi

TARGETS=()
[ -d "$HOME/.zcode" ]  && TARGETS+=("$HOME/.zcode/skills/fugui")
[ -d "$HOME/.claude" ] && TARGETS+=("$HOME/.claude/skills/fugui")
[ -d "$HOME/.codex" ]  && TARGETS+=("$HOME/.codex/skills/fugui")
if [ ${#TARGETS[@]} -eq 0 ]; then
  echo "未检测到 ~/.zcode ~/.claude ~/.codex，安装到 ~/.claude/skills/fugui（Claude Code 默认）"
  TARGETS=("$HOME/.claude/skills/fugui")
fi

for t in "${TARGETS[@]}"; do
  mkdir -p "$(dirname "$t")"
  rm -rf "$t"
  cp -R "$TMP/fugui" "$t"
  echo "✅ 已安装: $t"
done

echo ""
echo "完成。新开会话后，直接说人话即可触发，例如："
echo '  「我的小红书笔记收藏挺高但就是不涨粉，为什么？」'
echo '  「帮我把这段卖点文案改成用户想听的话」'
