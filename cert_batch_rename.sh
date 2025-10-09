#!/system/bin/sh

# Android CA证书智能批量重命名脚本
# 用法: ./cert_batch_rename.sh [证书目录路径]
# 如果不提供参数，将自动处理当前目录

echo "=== Android CA证书智能批量重命名工具 ==="
echo ""

# 确定工作目录
if [ $# -eq 0 ]; then
    # 获取脚本所在目录作为工作目录
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    CERT_DIR="$SCRIPT_DIR"
    echo "自动使用脚本所在目录: $CERT_DIR"
else
    CERT_DIR="$1"
    # 检查目录是否存在
    if [ ! -d "$CERT_DIR" ]; then
        echo "错误: 目录不存在: $CERT_DIR"
        exit 1
    fi
    echo "正在扫描指定目录: $CERT_DIR"
fi

# 检查是否有openssl命令
if ! command -v openssl >/dev/null 2>&1; then
    echo "错误: 系统中未找到openssl命令"
    echo "请确保您的Android系统或Termux中已安装openssl"
    exit 1
fi

# 计数器
PROCESSED=0
FAILED=0

# 切换到工作目录
cd "$CERT_DIR" || {
    echo "错误: 无法切换到目录: $CERT_DIR"
    exit 1
}

# 处理所有证书文件
for CERT_FILE in *.crt *.pem *.cer; do
    # 检查文件是否真实存在（避免通配符无匹配时的问题）
    [ -f "$CERT_FILE" ] || continue
    
    echo ""
    echo "--- 处理文件: $(basename "$CERT_FILE") ---"
    
    # 计算证书哈希值
    HASH=$(openssl x509 -inform PEM -subject_hash_old -in "$CERT_FILE" -noout 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$HASH" ]; then
        echo "❌ 跳过: 无法计算哈希值 (可能不是有效的证书文件)"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    echo "证书哈希值: $HASH"
    
    # 生成新文件名
    NEW_NAME="${HASH}.0"
    NEW_PATH="${CERT_DIR}/${NEW_NAME}"
    
    # 检查是否与原文件名相同
    if [ "$(basename "$CERT_FILE")" = "$NEW_NAME" ]; then
        echo "✅ 文件名已正确: $NEW_NAME"
        PROCESSED=$((PROCESSED + 1))
        continue
    fi
    
    # 检查目标文件是否已存在
    if [ -f "$NEW_PATH" ]; then
        echo "⚠️  目标文件已存在，跳过: $NEW_NAME"
        continue
    fi
    
    # 复制文件到新名称
    cp "$CERT_FILE" "$NEW_PATH"
    
    if [ $? -eq 0 ]; then
        echo "✅ 成功重命名为: $NEW_NAME"
        PROCESSED=$((PROCESSED + 1))
    else
        echo "❌ 重命名失败"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=== 批量处理完成 ==="
echo "成功处理: $PROCESSED 个文件"
echo "失败/跳过: $FAILED 个文件"
echo ""
echo "📋 后续步骤:"
echo "1. 将所有 *.0 文件复制到Magisk模块目录:"
echo "   system/etc/security/cacerts/"
echo ""
echo "2. 使用以下命令批量复制:"
echo "   cp \"$CERT_DIR\"/*.0 /path/to/magisk/module/system/etc/security/cacerts/"
echo ""
echo "3. 重新打包并安装Magisk模块"