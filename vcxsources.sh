#!/bin/bash

if [ -z "$1" ]; then
    echo "USAGE: $0 <my.vcxproj>" 1>&2
    exit 1
fi

grep 'ClCompile' "$1" |perl -w -p -e 's/\A\s+\<\/?ClCompile\>//;s/\r//g; s/\A\s*\<ClCompile Include="//; s#"\s*/\>##; s#\\#/#g; s/\A\n\Z//;' |sort |uniq
exit 0


