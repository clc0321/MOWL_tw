#!/bin/bash
#
# 這個文件是 MagiskOnWSALocal 的一部分。
#
# MagiskOnWSALocal 是免費軟件：您可以重新分發和/或修改它
# 它根據 GNU Affero 通用公共許可證的條款作為
# 由自由軟件基金會發布，無論是第 3 版還是
# 許可證，或（由您選擇）任何更高版本。
#
# MagiskOnWSALocal 是分發的，希望它有用，
# 但沒有任何保證； 甚至沒有默示保證
# 適銷性或適合特定用途。 見
# GNU Affero 通用公共許可證了解更多詳情。
#
# 你應該已經收到一份 GNU Affero 通用公共許可證
# 與 MagiskOnWSALocal 一起。 如果沒有，請參閱 <https://www.gnu.org/licenses/>。
#
# 版權所有 (C) 2023 LSPosed 貢獻者
#

# DEBUG=--debug
# CUSTOM_MAGISK=--magisk-custom
if [ ! "$BASH_VERSION" ]; then
    echo "請不要使用sh來運行這個腳本，直接執行即可" 1>&2
    exit 1
fi
cd "$(dirname "$0")" || exit 1

./install_deps.sh

WHIPTAIL=$(command -v whiptail 2>/dev/null)
DIALOG=$(command -v dialog 2>/dev/null)
DIALOG=${WHIPTAIL:-$DIALOG}
function Radiolist {
    declare -A o="$1"
    shift
    if ! $DIALOG --nocancel --radiolist "${o[title]}" 0 0 0 "$@" 3>&1 1>&2 2>&3; then
        echo "${o[default]}"
    fi
}

function YesNoBox {
    declare -A o="$1"
    shift
    $DIALOG --title "${o[title]}" --yesno "${o[text]}" 0 0
}

ARCH=$(
    Radiolist '([title]="構建版本"
                [default]="x64")' \
        \
        'x64' "X86_64" 'on' \
        'arm64' "AArch64" 'off'
)

RELEASE_TYPE=$(
    Radiolist '([title]="WSA 版本類型"
                [default]="retail")' \
        \
        'retail' "Stable Channel" 'on' \
        'release preview' "Release Preview Channel" 'off' \
        'insider slow' "Beta Channel" 'off' \
        'insider fast' "Dev Channel" 'off'
)

if [ -z "${CUSTOM_MAGISK+x}" ]; then
    MAGISK_VER=$(
        Radiolist '([title]="Magisk版本"
                        [default]="stable")' \
            \
            'stable' "Stable Channel" 'on' \
            'beta' "Beta Channel" 'off' \
            'canary' "Canary Channel" 'off' \
            'debug' "Canary Channel Debug Build" 'off'
    )
else
    MAGISK_VER=debug
fi

if (YesNoBox '([title]="安裝 GApp" [text]="您要安裝 GApps 嗎？")'); then
    GAPPS_BRAND=$(
        Radiolist '([title]="您要安裝哪種GApp?"
                 [default]="MindTheGapps")' \
            \
            'OpenGApps' "這種版本可能會導致啟動失敗" 'off' \
            'MindTheGapps' "推薦" 'on'
    )
else
    GAPPS_BRAND="none"
fi
if [ "$GAPPS_BRAND" = "OpenGApps" ]; then
    # TODO: Keep it pico since other variants of opengapps are unable to boot successfully
    if [ "$DEBUG" = "1" ]; then
    GAPPS_VARIANT=$(
        Radiolist '([title]="GApp 的變體"
                     [default]="pico")' \
            \
            'super' "" 'off' \
            'stock' "" 'off' \
            'full' "" 'off' \
            'mini' "" 'off' \
            'micro' "" 'off' \
            'nano' "" 'off' \
            'pico' "" 'on' \
            'tvstock' "" 'off' \
            'tvmini' "" 'off'
    )
    else
        GAPPS_VARIANT=pico
    fi
else
    GAPPS_VARIANT="pico"
fi

if (YesNoBox '([title]="刪除亞馬遜應用商店" [text]="你想保留 Amazon Appstore 嗎？")'); then
    REMOVE_AMAZON=""
else
    REMOVE_AMAZON="--remove-amazon"
fi

ROOT_SOL=$(
    Radiolist '([title]="Root 版本"
                     [default]="magisk")' \
        \
        'magisk' "Magisk" 'on' \
        'kernelsu' "KernelSU" 'off' \
        'none' "不要Root" 'off'
)

if (YesNoBox '([title]="Compress output" [text]="Do you want to compress the output?")'); then
    COMPRESS_OUTPUT="--compress"
else
    COMPRESS_OUTPUT=""
fi
if [ "$COMPRESS_OUTPUT" = "--compress" ]; then
    COMPRESS_FORMAT=$(
        Radiolist '([title]="壓縮格式"
                        [default]="7z")' \
            \
            'zip' "Zip" 'off' \
            '7z' "7-Zip" 'on' \
            'xz' "tar.xz" 'off'
        )
fi
# if (YesNoBox '([title]="Off line mode" [text]="Do you want to enable off line mode?")'); then
#     OFFLINE="--offline"
# else
#     OFFLINE=""
# fi
# OFFLINE="--offline"
clear
declare -A RELEASE_TYPE_MAP=(["retail"]="retail" ["release preview"]="RP" ["insider slow"]="WIS" ["insider fast"]="WIF")
COMMAND_LINE=(--arch "$ARCH" --release-type "${RELEASE_TYPE_MAP[$RELEASE_TYPE]}" --magisk-ver "$MAGISK_VER" --gapps-brand "$GAPPS_BRAND" --gapps-variant "$GAPPS_VARIANT" "$REMOVE_AMAZON" --root-sol "$ROOT_SOL" "$COMPRESS_OUTPUT" "$OFFLINE" "$DEBUG" "$CUSTOM_MAGISK" --compress-format "$COMPRESS_FORMAT")
echo "COMMAND_LINE=${COMMAND_LINE[*]}"
./build.sh "${COMMAND_LINE[@]}"
