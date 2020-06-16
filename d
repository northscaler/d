#!/usr/bin/env sh
set -e

usage() {
  USAGE="
d, a Deno-invoking version manager

Usage: $0 [deno-options]
Usage: $0 [d-options] [-- [deno-options]]

There are no required arguments.
If there is no \"--\" option on amongst the arguments, all arguments are passed along to Deno.
Otherwise, all $0 options must precede \"--\", and all arguments following it are passed along to Deno.

Options:
  -u, --use version:    Use the Deno version \"version\"; default is according to the rules below.
  -d, --d-home dir:     Use \"dir\" as the d home directory; default \"~/.d\".
  -r, --rc filename:    Use \"filename\" as the name of the d rc file to search for; default \".drc\".
  -x, --executable exe: Use \"exe\" as the Deno executuable; default \"deno\".
  -h, --help:           Display this message; for Deno help, use \"$0 -- --help\".
  --:                   Pass arguments preceding this to d, and pass arguments following it to Deno.

Version search rules, in order of precedence:
1. d command line argument \"-u\" or \"--use\".
2. Environment variable \"DENO_VERSION\".
3. The d rc file up the current directory tree, beginning in the current directory.
4. The d rc file in the user's home directory.
5. d rc file in the d home directory.
6. The file \".drc\" in the d home directory.
"
  echo "$USAGE"
}

DENO_D_SEP_RX='(^--$|^--\s+|\s+--$|\s+--\s+)'
if ! echo -n "$@" | egrep -q "$DENO_D_SEP_RX" && echo -n "$@" | egrep -q '(-h|--help)'; then
  usage
  exit 0
fi

if ! echo -n "$@" | egrep -q "$DENO_D_SEP_RX"; then
  DENO_ARGS="$@"
else
  while [ -n "$*" ]; do
    case "$1" in
    -u | --use)
      shift
      DENO_VERSION="$1"
      shift
      ;;
    -d | --d-home)
      shift
      DENO_D_HOME="$1"
      shift
      ;;
    -r | --rc)
      shift
      DENO_D_RC="$1"
      shift
      ;;
    -x | --executable)
      shift
      DENO="$1"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      DENO_ARGS="$@"
      break
      ;;
    *)
      echo "Error: unknown argument: $1"
      exit 1
      ;;
    esac
  done
fi

DENO_D_RC=${DENO_D_RC:-.drc}
DENO_D_HOME=${DENO_D_HOME:-"$HOME/.d"}

if [ -z "$DENO_D_ARCH" ]; then
  case $(uname -s) in
  Darwin)
    DENO_D_ARCH="x86_64-apple-darwin"
    ;;
  *)
    DENO_D_ARCH="x86_64-unknown-linux-gnu"
    ;;
  esac
fi

if [ -z "$DENO_VERSION" ]; then # no command line arg given or envvar for deno version
  d=$(pwd)
  while true; do # look up the directory tree for the rc file
    if [ -f "$d/$DENO_D_RC" ]; then
      DENO_VERSION="$(cat "$d/$DENO_D_RC")"
      break
    fi
    if [ $d == '/' ]; then
      break
    fi
    d=$(dirname $d)
  done

  if [ -z "$DENO_VERSION" ]; then # rc not up the dir tree
    if [ -f "$HOME/$DENO_D_RC" ]; then # check the user's home dir
      DENO_VERSION="$(cat "$HOME/$DENO_D_RC")"
    elif [ -f "$DENO_D_HOME/$DENO_D_RC" ]; then # check the `d` home dir
      DENO_VERSION="$(cat "$DENO_D_HOME/$DENO_D_RC")"
    elif [ -f "$DENO_D_HOME/.drc" ]; then # check the `d` home dir for the default rc file
      DENO_VERSION="$(cat "$DENO_D_HOME/.drc")"
    fi
  fi
fi

DENO_D_V_PREFIX=$(echo "$DENO_VERSION" | cut -c1-1)
if [ -n "$DENO_VERSION" ] && [ v != "$DENO_D_V_PREFIX" ]; then
  DENO_VERSION="v$DENO_VERSION"
fi

if [ -z "$DENO_VERSION" ]; then # find the latest version
  DENO_D_ASSET_PATH="$(curl -sSLf https://github.com/denoland/deno/releases | grep -o "/denoland/deno/releases/download/.*/deno-${DENO_D_ARCH}\\.zip" | head -n 1)"
  DENO_VERSION="$(echo "$DENO_D_ASSET_PATH" | awk -F '/' '{ print $6 }')"
  if [ ! "$DENO_D_ASSET_PATH" ]; then
    echo "Error: Unable to find latest Deno release on GitHub." 1>&2
    exit 3
  fi
  DENO_D_URI="https://github.com${DENO_D_ASSET_PATH}"
else
  DENO_D_URI="https://github.com/denoland/deno/releases/download/${DENO_VERSION}/deno-${DENO_D_ARCH}.zip"
fi

if [ ! -d "$DENO_D_HOME/$DENO_VERSION" ]; then
  mkdir -p "$DENO_D_HOME"
  DENO_D_ZIP_FILE=$(echo "$DENO_D_URI" | egrep -o "deno-$DENO_D_ARCH.zip$")
  if [ ! -f "$DENO_D_HOME/$DENO_D_ZIP_FILE" ]; then # download
    curl -sSLf $DENO_D_URI -o "$DENO_D_HOME/$DENO_VERSION.zip"
  fi
  unzip -d "$DENO_D_HOME/$DENO_VERSION" "$DENO_D_HOME/$DENO_VERSION.zip"
fi

DENO=${DENO:-deno}

"$DENO_D_HOME/$DENO_VERSION/$DENO" $DENO_ARGS
