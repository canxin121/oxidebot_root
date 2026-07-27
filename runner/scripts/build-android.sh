#!/usr/bin/env bash
# Build the Android command-line binary with the Android NDK's Clang toolchain.
# Usage: bash scripts/build-android.sh [cargo-target ...]
set -euo pipefail

readonly project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

readonly DEFAULT_API_LEVEL=24
readonly api_level="${ANDROID_API_LEVEL:-$DEFAULT_API_LEVEL}"
readonly sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android}}"

ndk_home="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
if [[ -z "$ndk_home" ]]; then
    shopt -s nullglob
    ndk_candidates=("$sdk_root"/ndk/*)
    shopt -u nullglob
    if (( ${#ndk_candidates[@]} > 0 )); then
        ndk_home="${ndk_candidates[${#ndk_candidates[@]} - 1]}"
    fi
fi

if [[ -z "$ndk_home" || ! -d "$ndk_home" ]]; then
    printf '%s\n' "Android NDK not found. Set ANDROID_NDK_HOME or install it with:" >&2
    printf '%s\n' "  sdkmanager --install 'ndk;29.0.14206865'" >&2
    exit 1
fi

readonly prebuilt_root="$ndk_home/toolchains/llvm/prebuilt"
host_toolchain=""
for candidate in darwin-arm64 darwin-x86_64 linux-x86_64; do
    if [[ -x "$prebuilt_root/$candidate/bin/clang" ]]; then
        host_toolchain="$prebuilt_root/$candidate"
        break
    fi
done

if [[ -z "$host_toolchain" ]]; then
    printf 'No supported host toolchain was found under %s\n' "$prebuilt_root" >&2
    exit 1
fi

if (( $# == 0 )); then
    targets=(
        aarch64-linux-android
        armv7-linux-androideabi
        x86_64-linux-android
        i686-linux-android
    )
else
    targets=("$@")
fi

rustup target add "${targets[@]}"

for target in "${targets[@]}"; do
    case "$target" in
        aarch64-linux-android) clang_prefix="aarch64-linux-android" ;;
        armv7-linux-androideabi) clang_prefix="armv7a-linux-androideabi" ;;
        x86_64-linux-android) clang_prefix="x86_64-linux-android" ;;
        i686-linux-android) clang_prefix="i686-linux-android" ;;
        *)
            printf 'Unsupported Android Rust target: %s\n' "$target" >&2
            exit 2
            ;;
    esac

    clang="$host_toolchain/bin/$clang_prefix$api_level-clang"
    if [[ ! -x "$clang" ]]; then
        printf 'Android Clang wrapper not found: %s\n' "$clang" >&2
        exit 1
    fi

    target_key="${target^^}"
    target_key="${target_key//-/_}"
    target_key_lower="${target//-/_}"
    printf 'Building %s (API %s)\n' "$target" "$api_level"
    env \
        "CARGO_TARGET_${target_key}_LINKER=$clang" \
        "CC_${target}=$clang" \
        "CC_${target_key_lower}=$clang" \
        "AR_${target_key_lower}=$host_toolchain/bin/llvm-ar" \
        cargo build --release --target "$target" --locked
done
