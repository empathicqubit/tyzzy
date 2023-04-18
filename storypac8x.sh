#! /bin/bash
set -e

READLINK="$(which greadlink readlink 2>/dev/null | head -1)"
DIR="$( cd "$( dirname "$("$READLINK" -f "$0")" )" > /dev/null && pwd )"

while [ ! -z "$1" ] ; do
    INPUT_FILE="$1"
    INPUT_DIR="${INPUT_FILE%.*}"
    INPUT_NAME="$(basename "${INPUT_FILE%.*}")"
    INPUT_NAME="${INPUT_NAME:0:6}"
    INPUT_NAME="${INPUT_NAME^^}"

    mkdir -p "$INPUT_DIR"
    split -b$((0x1f00)) "$INPUT_FILE" "$INPUT_DIR/$INPUT_NAME"
    for each in "$INPUT_DIR/$INPUT_NAME"?? ; do
        "$DIR/bashpac8x.sh" --variable --archive <( cat <(echo -ne "**TYZZY*") "$each" ) "$(basename "$each")" > "$each.8xv"
        rm "$each"
    done

    shift
done
