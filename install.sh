#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GHOSTTY_DIR=${XDG_CONFIG_HOME:-"$HOME/.config"}/ghostty
SHADER_DIR=$GHOSTTY_DIR/shaders
CONFIG_FILE=$GHOSTTY_DIR/config
SOURCE_SHADER=$PROJECT_DIR/shaders/warp-stars.glsl
DEST_SHADER=$SHADER_DIR/warp-stars.glsl
BEGIN_MARKER="# BEGIN ghostty-warp-stars"
END_MARKER="# END ghostty-warp-stars"

remove_managed_block() {
    source_file=$1
    target_file=$2

    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
        $0 == begin { managed = 1; next }
        $0 == end   { managed = 0; next }
        !managed    { print }
    ' "$source_file" > "$target_file"
}

validate_config() {
    if command -v ghostty >/dev/null 2>&1; then
        ghostty +validate-config
        printf '%s\n' "Ghostty configuration is valid."
    else
        printf '%s\n' "Ghostty is not in PATH; skipped configuration validation."
    fi
}

uninstall() {
    if [ -f "$CONFIG_FILE" ] && grep -Fq "$BEGIN_MARKER" "$CONFIG_FILE"; then
        backup="$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
        temporary="$CONFIG_FILE.tmp.$$"
        cp "$CONFIG_FILE" "$backup"
        remove_managed_block "$CONFIG_FILE" "$temporary"
        mv "$temporary" "$CONFIG_FILE"
        printf 'Removed managed configuration block. Backup: %s\n' "$backup"
    else
        printf '%s\n' "No managed configuration block found."
    fi

    if [ -f "$DEST_SHADER" ]; then
        rm "$DEST_SHADER"
        printf 'Removed %s\n' "$DEST_SHADER"
    fi

    validate_config
    printf '%s\n' "Reload Ghostty to finish uninstalling Warp Stars."
}

if [ "${1:-}" = "--uninstall" ]; then
    uninstall
    exit 0
fi

if [ "$#" -gt 0 ]; then
    printf 'Usage: %s [--uninstall]\n' "$0" >&2
    exit 2
fi

if [ ! -f "$SOURCE_SHADER" ]; then
    printf 'Missing source shader: %s\n' "$SOURCE_SHADER" >&2
    exit 1
fi

mkdir -p "$SHADER_DIR"

if [ -f "$DEST_SHADER" ] && ! cmp -s "$SOURCE_SHADER" "$DEST_SHADER"; then
    shader_backup="$DEST_SHADER.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$DEST_SHADER" "$shader_backup"
    printf 'Backed up existing shader to %s\n' "$shader_backup"
fi

cp "$SOURCE_SHADER" "$DEST_SHADER"
printf 'Installed shader at %s\n' "$DEST_SHADER"

mkdir -p "$GHOSTTY_DIR"
touch "$CONFIG_FILE"

if grep -Fq "$BEGIN_MARKER" "$CONFIG_FILE"; then
    printf '%s\n' "Ghostty configuration already contains the managed Warp Stars block."
elif grep -Fqx "custom-shader = $DEST_SHADER" "$CONFIG_FILE"; then
    printf '%s\n' "Ghostty configuration already references the installed shader."
else
    config_backup="$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$CONFIG_FILE" "$config_backup"
    cat >> "$CONFIG_FILE" <<EOF

$BEGIN_MARKER
custom-shader = $DEST_SHADER
custom-shader-animation = always
$END_MARKER
EOF
    printf 'Updated Ghostty configuration. Backup: %s\n' "$config_backup"
fi

validate_config
cat <<'EOF'

Warp Stars is installed. Reload Ghostty:
  macOS: Cmd+Shift+,
  Linux: Ctrl+Shift+,

For optional Herdr setup, see README.md.
EOF
