#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

load_env_file() {
    if [[ -f "${ENV_FILE}" ]]; then
        echo "Loading config from ${ENV_FILE}"
        set -a
        # shellcheck disable=SC1090
        source "${ENV_FILE}"
        set +a
    else
        echo "No .env found. Using default settings."
    fi
}

is_positive_integer() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

set_plist_value() {
    local plist_path="$1"
    local key="$2"
    local value="$3"

    plutil -replace "${key}" -string "${value}" "${plist_path}" 2>/dev/null || \
        plutil -insert "${key}" -string "${value}" "${plist_path}"
}

set_strings_value() {
    local strings_path="$1"
    local key="$2"
    local value="$3"
    local tmp_utf8

    tmp_utf8="$(mktemp)"

    iconv -f UTF-16 -t UTF-8 "${strings_path}" > "${tmp_utf8}"

    STRINGS_KEY="${key}" STRINGS_VALUE="${value}" perl -0pi -e '
        my $key = $ENV{STRINGS_KEY};
        my $pattern = quotemeta($key);
        my $value = $ENV{STRINGS_VALUE};
        $value =~ s/\\/\\\\/g;
        $value =~ s/"/\\"/g;

        if ($_ !~ s/"$pattern"\s*=\s*"(?:\\.|[^"])*";/"$key" = "$value";/sg) {
            $_ .= "\n\"$key\" = \"$value\";\n";
        }
    ' "${tmp_utf8}"

    printf '\377\376' > "${strings_path}"
    iconv -f UTF-8 -t UTF-16LE "${tmp_utf8}" >> "${strings_path}"
    rm -f "${tmp_utf8}"
}

update_localized_display_names() {
    local contents_dir="$1"
    local display_name="$2"
    local strings_file

    while IFS= read -r -d '' strings_file; do
        set_strings_value "${strings_file}" "CFBundleName" "${display_name}"
        set_strings_value "${strings_file}" "CFBundleDisplayName" "${display_name}"
    done < <(find "${contents_dir}" -name "InfoPlist.strings" -print0 2>/dev/null)
}

load_env_file

BASE_APP="${BASE_APP:-/Applications/KakaoTalk.app}"
TARGET_DIR="${TARGET_DIR:-/Applications}"
KAKAO_MULTI_COUNT="${KAKAO_MULTI_COUNT:-4}"
KAKAO_MULTI_APP_NAME_PREFIX="${KAKAO_MULTI_APP_NAME_PREFIX:-카카오톡-r}"
KAKAO_MULTI_DISPLAY_NAME_PREFIX="${KAKAO_MULTI_DISPLAY_NAME_PREFIX:-카카오톡-r}"
KAKAO_MULTI_NUMBER_WIDTH="${KAKAO_MULTI_NUMBER_WIDTH:-2}"
KAKAO_MULTI_EXECUTABLE_PREFIX="${KAKAO_MULTI_EXECUTABLE_PREFIX:-KakaoTalkMulti}"
KAKAO_MULTI_BUNDLE_ID_PREFIX="${KAKAO_MULTI_BUNDLE_ID_PREFIX:-com.kakao.multi}"
LSREGISTER_BIN="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if ! is_positive_integer "${KAKAO_MULTI_COUNT}"; then
    echo "KAKAO_MULTI_COUNT must be a positive integer."
    exit 1
fi

if ! is_positive_integer "${KAKAO_MULTI_NUMBER_WIDTH}"; then
    echo "KAKAO_MULTI_NUMBER_WIDTH must be a positive integer."
    exit 1
fi

if [[ ! -d "${BASE_APP}" ]]; then
    echo "Base app not found: ${BASE_APP}"
    exit 1
fi

if [[ ! -d "${TARGET_DIR}" ]]; then
    echo "Target directory not found: ${TARGET_DIR}"
    exit 1
fi

if ! command -v plutil >/dev/null 2>&1; then
    echo "plutil command not found."
    exit 1
fi

BASE_PLIST="${BASE_APP}/Contents/Info.plist"
BASE_EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${BASE_PLIST}" 2>/dev/null || true)"
BASE_EXECUTABLE_NAME="${BASE_EXECUTABLE_NAME:-KakaoTalk}"

for ((index = 1; index <= KAKAO_MULTI_COUNT; index++)); do
    printf -v NUM "%0${KAKAO_MULTI_NUMBER_WIDTH}d" "${index}"

    APP_NAME="${KAKAO_MULTI_APP_NAME_PREFIX}${NUM}"
    DISPLAY_NAME="${KAKAO_MULTI_DISPLAY_NAME_PREFIX}${NUM}"
    APP_PATH="${TARGET_DIR}/${APP_NAME}.app"
    PLIST_PATH="${APP_PATH}/Contents/Info.plist"
    EXECUTABLE_NAME="${KAKAO_MULTI_EXECUTABLE_PREFIX}${NUM}"
    ORIGINAL_EXECUTABLE_PATH="${APP_PATH}/Contents/MacOS/${BASE_EXECUTABLE_NAME}"
    NEW_EXECUTABLE_PATH="${APP_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"
    BUNDLE_ID="${KAKAO_MULTI_BUNDLE_ID_PREFIX}.${NUM}"

    echo "=============================="
    echo "Creating ${APP_NAME}"
    echo "=============================="

    rm -rf "${APP_PATH}"
    cp -a "${BASE_APP}" "${APP_PATH}"

    if [[ ! -f "${ORIGINAL_EXECUTABLE_PATH}" ]]; then
        echo "Executable not found in copied app: ${ORIGINAL_EXECUTABLE_PATH}"
        exit 1
    fi

    mv "${ORIGINAL_EXECUTABLE_PATH}" "${NEW_EXECUTABLE_PATH}"

    set_plist_value "${PLIST_PATH}" "CFBundleName" "${DISPLAY_NAME}"
    set_plist_value "${PLIST_PATH}" "CFBundleDisplayName" "${DISPLAY_NAME}"
    set_plist_value "${PLIST_PATH}" "CFBundleExecutable" "${EXECUTABLE_NAME}"
    set_plist_value "${PLIST_PATH}" "CFBundleIdentifier" "${BUNDLE_ID}"

    update_localized_display_names "${APP_PATH}/Contents" "${DISPLAY_NAME}"

    codesign --force --deep --sign - "${APP_PATH}"
    if [[ -x "${LSREGISTER_BIN}" ]]; then
        "${LSREGISTER_BIN}" -f "${APP_PATH}" >/dev/null 2>&1 || true
    fi
    touch "${APP_PATH}"

    echo "${APP_NAME} created successfully. Display name: ${DISPLAY_NAME}"
done

echo ""
echo "All KakaoTalk clones created."
