#!/bin/sh -e

base_dir=$(cd "${0%/*}/.." && pwd -P)
res_dir=${base_dir}/resources/images/kantone

sprite_png=${res_dir}/sprite.png
sprite_css=${res_dir}/sprite.css

command -v convert >/dev/null 2>&1 || {
	echo 'Cannot find convert binary.' >&2
	exit 1
}

test ! -f "${sprite_png}" || rm "${sprite_png}"

while read -r c1 c2
do
	if test -n "${c2}"
	then
		convert "${res_dir}/${c1}.png" "${res_dir}/${c2}.png" -background 'rgba(0,0,0,0)' +append _t.png
	else
		cat "${res_dir}/${c1}.png" >_t.png
	fi

	set --
	if test -s "${sprite_png}"
	then
		set -- "$@" "${sprite_png}"
	fi
	set -- "$@" _t.png
	
	convert "$@"  -background 'rgba(0,0,0,0)' -append "${sprite_png}"

	t_sz=$(identify -format '%g' _t.png)
	t_height=$(expr "${t_sz}" : '[0-9]\{1,\}x\([0-9]\{1,\}\)')

	rm _t.png

	c1_sz=$(identify -format '%g' "${res_dir}/${c1}.png")
	c1_width=$(expr "${c1_sz}" : '\([0-9]\{1,\}\)x')
	c1_height=$(expr "${c1_sz}" : '[0-9]\{1,\}x\([0-9]\{1,\}\)')

	printf '.canton-%s {\n  width: %upx;\n  height: %upx;\n  background: url(%s) 0px -%upx;\n}\n' \
		"${c1}" \
		$((c1_width)) $((c1_height)) \
		"${sprite_png#${res_dir}/}" $((offset_y))

	if test -n "${c2}"
	then
		offset_x=$((c1_width))

		c2_sz=$(identify -format '%g' "${res_dir}/${c2}.png")
		c2_width=$(expr "${c2_sz}" : '\([0-9]\{1,\}\)x')
		c2_height=$(expr "${c2_sz}" : '[0-9]\{1,\}x\([0-9]\{1,\}\)')

		printf '.canton-%s {\n  width: %upx;\n  height: %upx;\n  background: url(%s) -%upx -%upx;\n}\n' \
			"${c2}" \
			$((c2_width)) $((c2_height)) \
			"${sprite_png#${res_dir}/}" $((offset_x)) $((offset_y))
	fi

	: $((offset_y += t_height))
done <<EOF >"${sprite_css}"
ZH
BE
LU
UR
SZ
OW NW
GL
ZG
FR
SO
BS BL
SH
AR AI
SG
GR
AG
TG
TI
VD
VS
NE
GE
JU
EOF