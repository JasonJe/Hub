#!/bin/bash

# =============================================================================
# Hub App 打包脚本
# 功能：构建 Release 版本 + 创建 DMG 安装包
# 用法：./build_release.sh [选项]
#   --sign    使用开发者证书签名（需要配置 SIGNING_IDENTITY）
#   --clean   构建前清理
# =============================================================================

set -e

# 配置
APP_NAME="Hub"
PROJECT_PATH="Sources/Hub/Hub.xcodeproj"
SCHEME="Hub"
CONFIGURATION="Release"
OUTPUT_DIR="./release"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"

# 版本号（从项目文件读取）
MARKETING_VERSION=$(grep -m1 "MARKETING_VERSION" "${PROJECT_PATH}/project.pbxproj" | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
BUILD_VERSION=$(grep -m1 "CURRENT_PROJECT_VERSION" "${PROJECT_PATH}/project.pbxproj" | sed 's/.*= \(.*\);/\1/' | tr -d ' ')

# 签名配置（如需签名，设置环境变量 SIGNING_IDENTITY）
# 示例：export SIGNING_IDENTITY="Developer ID Application: Your Name (XXXXXX)"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 解析参数
DO_SIGN=false
DO_CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --sign)
            DO_SIGN=true
            shift
            ;;
        --clean)
            DO_CLEAN=true
            shift
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

# 显示配置信息
echo ""
echo "=============================================="
echo "  ${APP_NAME} Release Builder"
echo "=============================================="
echo "  版本号:   ${MARKETING_VERSION}"
echo "  构建号:   ${BUILD_VERSION}"
echo "  配置:     ${CONFIGURATION}"
echo "  签名:     $([ "$DO_SIGN" = true ] && echo "启用" || echo "禁用")"
echo "  输出目录: ${OUTPUT_DIR}"
echo "=============================================="
echo ""

# 清理
if [ "$DO_CLEAN" = true ]; then
    log_info "清理构建目录..."
    rm -rf "${OUTPUT_DIR}"
    xcodebuild clean -project "${PROJECT_PATH}" -scheme "${SCHEME}" -configuration "${CONFIGURATION}" >/dev/null 2>&1 || true
fi

# 创建输出目录
mkdir -p "${OUTPUT_DIR}"

# 构建 Release 版本
log_info "构建 ${CONFIGURATION} 版本..."
BUILD_START=$(date +%s)

xcodebuild archive \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${OUTPUT_DIR}/${APP_NAME}.xcarchive" \
    -destination 'platform=macOS' \
    ARCHIVE=YES \
    | xcpretty --color 2>/dev/null || xcodebuild archive \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${OUTPUT_DIR}/${APP_NAME}.xcarchive" \
    -destination 'platform=macOS' \
    ARCHIVE=YES

BUILD_END=$(date +%s)
log_success "构建完成 (耗时 $((BUILD_END - BUILD_START)) 秒)"

# 导出 App
log_info "导出应用..."
APP_PATH="${OUTPUT_DIR}/${APP_NAME}.app"

# 从 archive 中提取 app
cp -R "${OUTPUT_DIR}/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app" "${OUTPUT_DIR}/"

if [ ! -d "${APP_PATH}" ]; then
    log_error "应用导出失败，未找到 ${APP_PATH}"
    exit 1
fi

log_success "应用已导出: ${APP_PATH}"

# 代码签名
if [ "$DO_SIGN" = true ]; then
    if [ -n "$SIGNING_IDENTITY" ]; then
        log_info "代码签名..."
        codesign --force --deep --sign "${SIGNING_IDENTITY}" "${APP_PATH}"
        log_success "签名完成"
        
        # 公证准备提示
        log_warning "签名完成后，建议进行公证："
        echo "  1. 创建 ZIP: ditto -c -k --keepParent \"${APP_PATH}\" \"${OUTPUT_DIR}/${APP_NAME}.zip\""
        echo "  2. 提交公证: xcrun notarytool submit \"${OUTPUT_DIR}/${APP_NAME}.zip\" --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID --password YOUR_APP_SPECIFIC_PASSWORD"
        echo "  3. 等待完成后，装订票据: xcrun stapler staple \"${APP_PATH}\""
    else
        log_error "未配置 SIGNING_IDENTITY 环境变量，跳过签名"
        log_warning "设置方法: export SIGNING_IDENTITY=\"Developer ID Application: Your Name (XXXXXX)\""
    fi
fi

# 创建 DMG
log_info "创建 DMG 安装包..."
DMG_PATH="${OUTPUT_DIR}/${APP_NAME}-${MARKETING_VERSION}.dmg"

# 临时 DMG 路径
TMP_DMG="/tmp/${APP_NAME}_tmp.dmg"
VOLUME_MOUNT="/Volumes/${VOLUME_NAME}"

# 清理可能存在的旧挂载
hdiutil detach "${VOLUME_MOUNT}" 2>/dev/null || true
rm -f "${TMP_DMG}"

# 创建临时文件夹
TMP_FOLDER="/tmp/${APP_NAME}_dmg"
rm -rf "${TMP_FOLDER}"
mkdir -p "${TMP_FOLDER}"

# 复制 app 到临时文件夹
cp -R "${APP_PATH}" "${TMP_FOLDER}/"

# 创建 Applications 快捷方式（用于拖拽安装）
ln -s /Applications "${TMP_FOLDER}/Applications"

# 创建 DMG
hdiutil create -volname "${VOLUME_NAME}" \
    -srcfolder "${TMP_FOLDER}" \
    -ov -format UDZO \
    -imagekey zlib-level=9 \
    "${DMG_PATH}"

# 清理临时文件
rm -rf "${TMP_FOLDER}"
rm -f "${TMP_DMG}"

log_success "DMG 已创建: ${DMG_PATH}"

# 签名 DMG
if [ "$DO_SIGN" = true ] && [ -n "$SIGNING_IDENTITY" ]; then
    log_info "签名 DMG..."
    codesign --force --sign "${SIGNING_IDENTITY}" "${DMG_PATH}"
    log_success "DMG 签名完成"
fi

# 显示构建信息
echo ""
echo "=============================================="
log_success "打包完成！"
echo "=============================================="
echo ""
echo "输出文件:"
echo "  App:  ${APP_PATH}"
echo "  DMG:  ${DMG_PATH}"
echo ""
echo "文件大小:"
APP_SIZE=$(du -sh "${APP_PATH}" | cut -f1)
DMG_SIZE=$(du -sh "${DMG_PATH}" | cut -f1)
echo "  App:  ${APP_SIZE}"
echo "  DMG:  ${DMG_SIZE}"
echo ""
echo "SHA256 校验和:"
shasum -a 256 "${DMG_PATH}"
echo ""

# 验证
log_info "验证应用..."
spctl --assess --verbose=4 --type execute "${APP_PATH}" 2>&1 || log_warning "应用未签名或签名验证失败（这是正常的，如果未启用签名）"

log_success "全部完成！"
