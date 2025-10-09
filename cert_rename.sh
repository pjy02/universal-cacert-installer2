#!/system/bin/sh

# Android CA证书自动重命名脚本
# 用法: ./cert_rename.sh [证书文件路径]
# 如果不提供参数，将自动处理当前目录下的所有证书文件

echo "=== Android CA证书自动重命名工具 ==="
echo ""

# 检查是否有openssl命令
if ! command -v openssl >/dev/null 2>&1; then
    echo "错误: 系统中未找到openssl命令"
    echo "请确保您的Android系统或Termux中已安装openssl"
    exit 1
fi

# 如果提供了参数，处理指定文件
if [ $# -gt 0 ]; then
    CERT_FILE="$1"
    
    # 检查文件是否存在
    if [ ! -f "$CERT_FILE" ]; then
        echo "错误: 证书文件不存在: $CERT_FILE"
        exit 1
    fi
    
    echo "正在处理指定证书文件: $CERT_FILE"
    process_single_cert "$CERT_FILE"
    exit 0
fi

# 自动处理脚本所在目录下的所有证书文件
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || {
    echo "错误: 无法切换到脚本目录: $SCRIPT_DIR"
    exit 1
}

echo "自动扫描脚本所在目录: $SCRIPT_DIR"
echo "支持的证书格式: .crt, .pem, .cer"
echo ""

# 计数器
PROCESSED=0
FAILED=0
FOUND=0

# 处理函数
process_single_cert() {
    local CERT_FILE="$1"
    local BASENAME=$(basename "$CERT_FILE")
    
    echo "--- 处理文件: $BASENAME ---"

    # 计算证书哈希值
    local HASH=$(openssl x509 -inform PEM -subject_hash_old -in "$CERT_FILE" -noout 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$HASH" ]; then
        echo "❌ 跳过: 无法计算哈希值 (可能不是有效的证书文件)"
        return 1
    fi
    
    echo "证书哈希值: $HASH"
    
    # 生成新文件名
    local NEW_NAME="${HASH}.0"
    local CERT_DIR=$(dirname "$CERT_FILE")
    local NEW_PATH="${CERT_DIR}/${NEW_NAME}"
    
    # 检查是否与原文件名相同
    if [ "$BASENAME" = "$NEW_NAME" ]; then
        echo "✅ 文件名已正确: $NEW_NAME"
        return 0
    fi
    
    # 检查目标文件是否已存在
    if [ -f "$NEW_PATH" ]; then
        echo "⚠️  目标文件已存在，跳过: $NEW_NAME"
        return 0
    fi
    
    # 复制文件到新名称
    cp "$CERT_FILE" "$NEW_PATH"
    
    if [ $? -eq 0 ]; then
        echo "✅ 成功重命名为: $NEW_NAME"
        return 0
    else
        echo "❌ 重命名失败"
        return 1
    fi
}

# 扫描并处理所有证书文件
for CERT_FILE in *.crt *.pem *.cer; do
    # 检查文件是否真实存在（避免通配符无匹配时的问题）
    [ -f "$CERT_FILE" ] || continue
    
    FOUND=$((FOUND + 1))
    
    if process_single_cert "$CERT_FILE"; then
        PROCESSED=$((PROCESSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

# 显示处理结果
if [ $FOUND -eq 0 ]; then
    echo "❌ 当前目录下未找到任何证书文件"
    echo "支持的格式: .crt, .pem, .cer"
    echo ""
    echo "用法提示:"
    echo "1. 将证书文件放在脚本同一目录下"
    echo "2. 运行: sh cert_rename.sh"
    echo "3. 或指定文件: sh cert_rename.sh /path/to/cert.crt"
    exit 1
fi

echo "=== 自动处理完成 ==="
echo "发现证书: $FOUND 个"
echo "成功处理: $PROCESSED 个"
echo "失败/跳过: $FAILED 个"
echo ""

if [ $PROCESSED -gt 0 ]; then
    echo "📋 后续步骤:"
    echo "1. 将所有 *.0 文件复制到Magisk模块目录:"
    echo "   system/etc/security/cacerts/"
    echo ""
    echo "2. 使用以下命令批量复制:"
    echo "   cp *.0 /path/to/magisk/module/system/etc/security/cacerts/"
    echo ""
    echo "3. 重新打包并安装Magisk模块"
fi