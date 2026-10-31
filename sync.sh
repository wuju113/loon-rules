#!/usr/bin/env bash
# 下载每个上游；失败或内容异常就保留旧文件
set -u
grep -v '^#' sources.txt | while IFS='|' read -r path url; do
  [ -z "$path" ] && continue
  mkdir -p "$(dirname "$path")"
  if curl -fsSL -m 60 "$url" -o tmp.dl && [ -s tmp.dl ] && ! grep -qi '<html' tmp.dl; then
    mv tmp.dl "$path"; echo "OK  $path"
  else
    rm -f tmp.dl; echo "KEEP $path (上游失败，保留旧版)"
  fi
done
