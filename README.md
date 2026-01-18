# ⚠️ 项目状态说明（重要）

> **本 Magisk 模块已停止维护，不再更新。**  
> 请使用新的统一模块项目，功能更完整、兼容性更好。

## ✅ 新模块项目（推荐）

👉 **Universal CA Cert Installer（通用 CA 证书安装器）**  
🔗 https://github.com/pjy02/universal-cacert-installer

后续 Android 新版本适配、问题修复与功能更新 **仅在新项目中进行**。

---
# 通用CA证书安装Magisk模块

## 📖 项目简介

这是一个通用的Magisk模块，用于将CA证书安装到Android系统的受信任证书存储中。支持批量安装多个证书，兼容Android 14的APEX机制，并提供智能的Android端证书重命名工具。

## ✨ 主要功能

- 🔄 **批量证书安装**：自动安装 `system/etc/security/cacerts/` 目录下的所有证书
- 📱 **Android 14兼容**：特别支持Android 14的APEX挂载机制
- 🛡️ **系统级集成**：通过Magisk实现systemless修改
- 🚀 **启动时自动执行**：系统启动时自动安装证书
- 🛠️ **智能重命名工具**：提供Android端证书重命名脚本
- 📦 **文件管理器支持**：支持在各种Android文件管理器中运行脚本
- 🔍 **智能自动扫描**：自动识别和处理脚本所在目录的证书文件

## 🏗️ 技术架构

- **开发语言**：Shell脚本
- **运行框架**：Magisk v20.4+
- **目标平台**：Android系统
- **核心依赖**：Android证书管理API, APEX挂载机制, OpenSSL

## 📁 项目结构

```
universal-cacert-installer/
├── README.md                     # 项目说明文档
├── module.prop                   # 模块配置文件
├── post-fs-data.sh              # 证书安装脚本
├── cert_rename.sh               # 智能证书重命名工具
├── cert_batch_rename.sh         # 批量证书重命名工具
├── ca.crt                       # 示例证书文件
├── META-INF/
│   └── com/google/android/
│       ├── update-binary        # Magisk安装脚本
│       └── updater-script
└── system/etc/security/cacerts/
    ├── 68685cc8.0              # Reqable证书
    └── bbb02ac9.0              # 用户证书
```

## 📋 使用方法

### 方法一：使用智能重命名工具（推荐）

#### 🔧 最简单用法
```bash
# 1. 将证书文件(.crt, .pem, .cer)和脚本放在同一目录
# 2. 直接运行脚本，无需任何参数
sh cert_rename.sh
```

#### 🔧 传统用法
```bash
# 指定具体证书文件
sh cert_rename.sh /path/to/certificate.crt

# 批量处理指定目录
sh cert_batch_rename.sh /path/to/certificates/
```

### 方法二：手动添加证书

1. 计算证书哈希值：`openssl x509 -inform PEM -subject_hash_old -in certificate.crt -noout`
2. 重命名证书为：`[哈希值].0`
3. 将重命名后的证书放入 `system/etc/security/cacerts/` 目录
4. 打包并安装Magisk模块

## 📝 证书命名规则

Android系统要求CA证书文件名必须是特定格式：

- **格式**：`[8位哈希值].0`
- **计算方法**：使用OpenSSL计算证书主题哈希值
- **命令**：`openssl x509 -inform PEM -subject_hash_old -in certificate.crt -noout`

### 示例
```bash
# 原文件：mycert.crt
# 计算哈希：bbb02ac9
# 重命名为：bbb02ac9.0
```

## 🚀 Android端使用指南

### 准备工作
1. 安装Termux或其他支持Shell的应用
2. 确保系统中有OpenSSL（Termux中运行：`pkg install openssl`）

### 在文件管理器中使用
1. 将证书文件和脚本解压到同一目录
2. 使用支持Shell的文件管理器运行脚本
3. 脚本会自动处理同目录下的所有证书文件

⚠️ **重要提示**：请不要在压缩包内直接运行脚本，这可能导致路径错误。请先解压文件到设备存储中再运行。

### 完整操作流程
```bash
# 1. 进入工作目录（不能在压缩包内）
cd /sdcard/Download/

# 2. 运行智能重命名脚本
sh cert_rename.sh

# 3. 查看生成的证书文件
ls -la *.0

# 4. 复制到模块目录（如果有模块源码）
cp *.0 /path/to/magisk/module/system/etc/security/cacerts/
```

## 🔧 模块安装

1. 将重命名后的证书文件放入 `system/etc/security/cacerts/` 目录
2. 打包整个模块为zip文件
3. 在Magisk Manager中安装模块
4. 重启设备使证书生效

## ⚠️ 注意事项

1. **权限要求**：需要root权限和Magisk v20.4+
2. **证书格式**：仅支持PEM格式的证书文件
3. **文件命名**：必须严格按照哈希值.0的格式命名
4. **安全性**：仅安装您信任的CA证书
5. **兼容性**：支持Android 5.0+，特别优化Android 14

## 🔧 故障排除

### 脚本运行错误
- 确保脚本有执行权限：`chmod +x cert_rename.sh`
- 检查OpenSSL是否安装：`which openssl`
- 验证证书文件格式是否正确

### 证书未生效
- 检查文件名是否正确（8位哈希值.0）
- 确认证书文件权限正确
- 查看模块日志：`cat /data/local/tmp/UniversalCACert.log`

### 脚本运行环境问题
- ⚠️ **不要在压缩包内运行**：请先解压文件到设备存储
- 确保证书文件和脚本在同一目录
- 使用支持Shell的文件管理器或终端应用
- 检查文件权限和OpenSSL可用性

## 📊 功能特性

| 功能 | 支持情况 |
|------|----------|
| 证书数量 | 批量支持 |
| Android 14 | ✅ |
| 重命名工具 | ✅ |
| 智能扫描 | ✅ |
| 文件管理器 | ✅ |
| 中文界面 | ✅ |

## 📞 技术支持

如果遇到问题，请检查：
1. Magisk版本是否为v20.4+
2. 证书文件格式是否为PEM
3. 文件命名是否符合规范
4. 系统日志中的错误信息

## 🔄 更新日志

### v2.0
- ✅ 支持批量证书安装
- ✅ 添加智能重命名工具
- ✅ 支持压缩包内运行
- ✅ 中文化界面
- ✅ 优化Android 14兼容性

### v1.0
- ✅ 基础单证书安装功能
- ✅ Android 14 APEX支持

## 📄 许可证

本项目遵循开源协议。

## 🔗 相关链接

- **项目名称**: Universal CA Certificate Installer
- **模块ID**: universal-cacert-installer

---

**免责声明**：请仅安装您信任的CA证书，恶意证书可能带来安全风险。使用本模块所产生的任何后果由用户自行承担。
