#!/usr/bin/env bash
# fugui.skill 一键安装脚本（v2.3 双通道版）
# 用法: curl -fsSL <raw-url>/install.sh | bash   或   FUGUI_CHANNEL=tarball bash install.sh
# 效果: 把 fugui/ 技能目录装到本机已存在的 Agent skills 目录（zcode / claude / codex）
# 通道: 默认 raw 按文件下载；raw 不可达时自动回退 codeload tarball 整包（网络受限环境友好）
set -euo pipefail

REPO="${FUGUI_REPO:-ZMKC404/fugui}"
BRANCH="${FUGUI_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
TARBALL_URL="https://codeload.github.com/${REPO}/tar.gz/refs/heads/${BRANCH}"
CHANNEL="${FUGUI_CHANNEL:-auto}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fetch_via_raw() {
  echo "⬇️  通道1: raw 按文件下载 ..."
  mkdir -p "$TMP/fugui/references" "$TMP/fugui/assets"
  curl -fsSL --max-time 20 "$RAW_BASE/fugui/SKILL.md" -o "$TMP/fugui/SKILL.md" || return 1
  for f in diagnose translate position strategy motivation convert ai-workflow case-library style-voice sales-psychology-liangkaopu canonical-quotes; do
    curl -fsSL --max-time 20 "$RAW_BASE/fugui/references/$f.md" -o "$TMP/fugui/references/$f.md" || return 1
  done
  for f in "内容自检表" "情绪锚点画布"; do
    curl -fsSL --max-time 20 "$RAW_BASE/fugui/assets/$f.md" -o "$TMP/fugui/assets/$f.md" || return 1
  done
  return 0
}

fetch_via_tarball() {
  echo "⬇️  通道2: codeload tarball 整包 ..."
  curl -fsSL --max-time 60 "$TARBALL_URL" -o "$TMP/repo.tar.gz" || return 1
  mkdir -p "$TMP/extract"
  tar -xzf "$TMP/repo.tar.gz" -C "$TMP/extract"
  [ -d "$TMP/extract/fugui-main/fugui" ] || return 1
  rm -rf "$TMP/fugui"
  cp -R "$TMP/extract/fugui-main/fugui" "$TMP/fugui"
  return 0
}

FETCHED=""
if [ "$CHANNEL" = "auto" ] || [ "$CHANNEL" = "raw" ]; then
  if fetch_via_raw; then FETCHED="raw"; fi
fi
if [ -z "$FETCHED" ] && { [ "$CHANNEL" = "auto" ] || [ "$CHANNEL" = "tarball" ]; }; then
  if fetch_via_tarball; then FETCHED="tarball"; fi
fi
if [ -z "$FETCHED" ]; then
  echo "❌ 两条下载通道均失败。请检查网络后重试，或手动克隆：git clone --depth 1 https://github.com/${REPO}.git"
  exit 1
fi
echo "✅ 下载完成（通道: ${FETCHED}）"

if ! grep -q "^name: fugui" "$TMP/fugui/SKILL.md" 2>/dev/null; then
  echo "❌ SKILL.md 校验失败，安装中止"; exit 1
fi
REFS=$(ls "$TMP/fugui/references" 2>/dev/null | wc -l | tr -d ' ')
echo "📦 校验通过: SKILL.md + references($REFS) + assets($(ls "$TMP/fugui/assets" | wc -l | tr -d ' '))"

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
