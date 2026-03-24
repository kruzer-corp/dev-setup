#!/bin/bash

echo "🔍 Checking environment..."

command -v node >/dev/null || echo "❌ Node missing"
command -v docker >/dev/null || echo "❌ Docker missing"
command -v direnv >/dev/null || echo "❌ Direnv missing"
command -v git >/dev/null || echo "❌ Git missing"

echo "✅ Done"
