#!/usr/bin/env bash
# 下载每个上游；失败或内容异常就保留旧文件
# sources.txt 每行：路径|规则URL[|域名集URL]
# 域名集（blackmatrix7 的 *_Domain.list）会转换成 DOMAIN / DOMAIN-SUFFIX 后合并进同一文件
set -u
ok() { [ -s "$1" ] && ! grep -qi '<html' "$1"; }
grep -v '^#' sources.txt | while IFS='|' read -r path url domurl; do
  [ -z "$path" ] && continue
  mkdir -p "$(dirname "$path")"
  if curl -fsSL -m 60 "$url" -o tmp.dl && ok tmp.dl; then
    if [ -n "${domurl:-}" ]; then
      if curl -fsSL -m 120 "$domurl" -o tmp.dom && ok tmp.dom; then
        printf '\n# ---- merged from %s ----\n' "$domurl" >> tmp.dl
        grep -v '^#' tmp.dom | tr -d '\r' | awk 'NF{ if (substr($0,1,1)==".") print "DOMAIN-SUFFIX," substr($0,2); else print "DOMAIN," $0 }' >> tmp.dl
      else
        rm -f tmp.dl tmp.dom; echo "KEEP $path (域名集失败，保留旧版)"; continue
      fi
    fi
    # Loon iOS 不支持 PROCESS-NAME，去掉
    sed -i '/^PROCESS-NAME,/d' tmp.dl
    mv tmp.dl "$path"; rm -f tmp.dom; echo "OK  $path"
  else
    rm -f tmp.dl; echo "KEEP $path (上游失败，保留旧版)"
  fi
done
