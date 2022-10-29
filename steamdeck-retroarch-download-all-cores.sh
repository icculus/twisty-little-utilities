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

RETROTMPDIR="$HOME/steamdeck_retroarch_core_update_tmp"
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

echo "$RETROVER" > "$LASTCHECKPATH"

echo
echo "$ME: Cores are updated to version $RETROVER!"
echo


# Let's grab some BIOSes some cores need...
# If this fails, oh well.
# These are all North American BIOSes, when given an option. This could be
# improved (do cores know which to load? Should we decide where this script
# is running from from timezone?)
# Feedback is needed in any case (which 3DO BIOS should I use?! etc).
RETROSYSTEMPATH="$RETROPATH/system"

# Nintendo Family Disk System for various NES/FDS emulators...
for FDSMODULE in disksys ; do
    ROMFILE="$FDSMODULE.rom"
    if [ ! -f "$RETROSYSTEMPATH/$ROMFILE" ]; then
        echo "Downloading Nintendo Family Disk System bios $ROMFILE ..."
        curl -L -o "$RETROSYSTEMPATH/$ROMFILE" "https://archive.org/download/verifiedbiosfiles/OGA%20BIOS/Nintendo%20Family%20Disk%20System/$ROMFILE"
    fi
done

# PlayStation 1 BIOS for PCSX ReARMed, etc.
for PS1MODULE in 5500 5501 5502 ; do
    ROMFILE="scph$PS1MODULE.bin"
    if [ ! -f "$RETROSYSTEMPATH/$ROMFILE" ]; then
        echo "Downloading PlayStation 1 bios $ROMFILE ..."
        curl -L -o "$RETROSYSTEMPATH/$ROMFILE" "https://archive.org/download/verifiedbiosfiles/OGA%20BIOS/PSX/$ROMFILE"
    fi
done

# PlayStation 2 BIOS for pcsx2...
mkdir -p "$RETROSYSTEMPATH/pcsx2/bios"
for PS2MODULE in bin MEC ; do
    for PS2BIOSVER in 39000 39001 39002 ; do
        ROMFILE="scph$PS2BIOSVER.$PS2MODULE"
        if [ ! -f "$RETROSYSTEMPATH/pcsx2/bios/$ROMFILE" ]; then
            echo "Downloading PlayStation 2 bios $ROMFILE ..."
            curl -L -o "$RETROSYSTEMPATH/pcsx2/bios/$ROMFILE" "https://archive.org/download/verifiedbiosfiles/OGA%20BIOS/PS2/$ROMFILE"
        fi
    done
done

# MSX BIOS for fMSX...
for MSXMODULE in DISK FMPAC KANJI MSX MSX2 MSX2EXT MSX2P MSX2PEXT MSXDOS2 PAINTER ; do
    ROMFILE="$MSXMODULE.ROM"
    if [ ! -f "$RETROSYSTEMPATH/$ROMFILE" ]; then
        echo "Downloading MSX bios $ROMFILE ..."
        curl -L -o "$RETROSYSTEMPATH/$ROMFILE" "https://archive.org/download/verifiedbiosfiles/OGA%20BIOS/MSX/$ROMFILE"
    fi
done

# Mattel Intellivision BIOS for FreeIntv...
for INTVMODULE in ECS IVOICE exec grom ; do
    ROMFILE="$INTVMODULE.bin"
    if [ ! -f "$RETROSYSTEMPATH/$ROMFILE" ]; then
        echo "Downloading Intellivision bios $ROMFILE ..."
        curl -L -o "$RETROSYSTEMPATH/$ROMFILE" "https://archive.org/download/verifiedbiosfiles/OGA%20BIOS/Mattel%20Intellivision/$ROMFILE"
    fi
done

# Sega Dreamcast BIOS for Flycast...
mkdir -p "$RETROSYSTEMPATH/dc"
for DCMODULE in boot ; do
    ROMFILE="dc_$DCMODULE.bin"
    if [ ! -f "$RETROSYSTEMPATH/dc/$ROMFILE" ]; then
        echo "Downloading Dreamcast bios $ROMFILE ..."
        curl -L -o "$RETROSYSTEMPATH/dc/$ROMFILE" "https://archive.org/download/verifiedbiosfiles/OGA%20BIOS/Dreamcast/$ROMFILE"
    fi
done

# Sega CD BIOS for Genesis Plus GX/PixoDrive/etc...
for SEGACDMODULE in E U J ; do
    ROMFILE="bios_CD_$SEGACDMODULE.bin"
    if [ ! -f "$RETROSYSTEMPATH/$ROMFILE" ]; then
        echo "Downloading Sega CD bios $ROMFILE ..."
        curl -L -o "$RETROSYSTEMPATH/$ROMFILE" "https://archive.org/download/verifiedbiosfiles/OGA%20BIOS/Sega%20CD/$ROMFILE"
    fi
done

# Preparation necessary for ScummVM games...
if [ ! -d "$RETROSYSTEMPATH/scummvm" ]; then
    echo "Downloading ScummVM required files ..."
    mkdir -p "$RETROTMPDIR"
    curl -L -o "$RETROTMPDIR/scummvm.zip" "https://github.com/libretro/scummvm/raw/master/backends/platform/libretro/aux-data/scummvm.zip" && unzip -d "$RETROSYSTEMPATH" "$RETROTMPDIR/scummvm.zip"
fi

if [ ! -f "$RETROSYSTEMPATH/scummvm/extra/MT32_PCM.ROM" ]; then
    echo "Downloading ScummVM Roland MT32 PCM ROM ..."
    curl -L -o "$RETROSYSTEMPATH/scummvm/extra/MT32_PCM.ROM" "https://archive.org/download/mame-versioned-roland-mt-32-and-cm-32l-rom-files/mt32-roms.zip/mt32-roms%2FMT32_PCM.ROM"
fi

if [ ! -f "$RETROSYSTEMPATH/scummvm/extra/MT32_CONTROL.ROM" ]; then
    echo "Downloading ScummVM Roland MT32 CONTROL ROM ..."
    curl -L -o "$RETROSYSTEMPATH/scummvm/extra/MT32_CONTROL.ROM" "https://archive.org/download/mame-versioned-roland-mt-32-and-cm-32l-rom-files/mt32-roms.zip/mt32-roms%2FMT32_PCM.ROM"
fi

if [ ! -f "$RETROSYSTEMPATH/scummvm.ini" ]; then
    echo "Creating a default ScummVM scummvm.ini ..."
    cat > "$RETROSYSTEMPATH/scummvm.ini" <<EOF
[scummvm]
filtering=false
mute=false
soundfont=$RETROSYSTEMPATH/scummvm/extra/Roland_SC-55.sf2
speech_volume=192
native_mt32=false
midi_gain=100
gui_theme=scummmodern
talkspeed=60
mt32_device=mt32
extrapath=$RETROSYSTEMPATH/scummvm/extra
subtitles=false
multi_midi=true
fullscreen=true
gui_browser_show_hidden=false
gm_device=fluidsynth
themepath=$RETROSYSTEMPATH/scummvm/theme
sfx_volume=192
music_volume=192
speech_mute=false
music_driver=auto
opl_driver=auto
aspect_ratio=false
versioninfo=2.1.1
autosave_period=300
enable_gs=false

EOF

    echo "ScummVM is set up for use, but you need to add games to the list."
    echo "Follow the directions at:"
    echo "  https://docs.libretro.com/library/scummvm/#game-management"
fi

# Remove any downloaded leftovers...
rm -rf "$RETROTMPDIR"

exit 0

