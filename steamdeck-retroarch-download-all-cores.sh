#!/bin/sh

#set -x

ME=`basename $0`
RETROPATH="$HOME/.local/share/Steam/steamapps/common/RetroArch"
RETROCOREPATH="$RETROPATH/cores"
RETROBIN="$RETROPATH/retroarch"

if [ ! -f "$RETROBIN" ]; then
    echo "RetroArch/steam doesn't appear to be installed. Giving up." 1>&2
    exit 1
fi

# Hopefully this string isn't going to change inside RetroArch.  :/
RETROVER=`strings "$RETROBIN" |grep '\[INFO\] Version:' |awk '{ print $3 }'`
if [ "x$RETROVER" = "x" ]; then
   echo "Couldn't figure out current RetroArch version." 1>&2
   exit 1
fi

LASTCHECKPATH="$HOME/.last_steamdeck_retroarch_core_update.txt"
LASTCHECKVER=`cat "$LASTCHECKPATH"`

if [ "x$RETROVER" = "x$LASTCHECKVER" ]; then
    exit 0    # already at latest version, exit quietly.
fi

echo
echo "$ME: Last seen version was '$LASTCHECKVER'"
echo "$ME: Current version appears to be '$RETROVER'"
echo "$ME: Updating!"
echo

RETROTMPDIR="$HOME/steamdeck_retroarch_core_update_tmp"
rm -rf "$RETROTMPDIR"
mkdir "$RETROTMPDIR"

RETROCOREURL="https://buildbot.libretro.com/stable/$RETROVER/linux/x86_64/RetroArch_cores.7z"
RETROCORE7ZPATH="$RETROTMPDIR/RetroArch_cores.7z"
RETROCORE7ZINTERNALPATH="RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch"
RETROINFOZIPPATH="$RETROTMPDIR/RetroArch_info.zip"
rm -f "$RETROCORE7ZPATH" "$RETROINFOZIPPATH"
curl -L -o "$RETROCORE7ZPATH" "$RETROCOREURL" || exit 1
curl -L -o "$RETROINFOZIPPATH" "https://buildbot.libretro.com/assets/frontend/info.zip"

RETROTMPPATH="$RETROTMPDIR/tmp"
rm -rf "$RETROTMPPATH"
mkdir "$RETROTMPPATH"
cd "$RETROTMPPATH"
7za x "$RETROCORE7ZPATH" "$RETROCORE7ZINTERNALPATH/cores" || exit 1
mv "$RETROCORE7ZINTERNALPATH/cores" .
cd cores
unzip -o "$RETROINFOZIPPATH" || exit 1
rm -f "$RETROCORE7ZPATH" "$RETROINFOZIPPATH"
cp -Rnv "$RETROTMPPATH"/cores/* "$RETROCOREPATH"/
rm -rf "$RETROTMPDIR"

echo "$RETROVER" > "$LASTCHECKPATH"

echo
echo "$ME: Cores are updated to version $RETROVER!"
echo

exit 0
