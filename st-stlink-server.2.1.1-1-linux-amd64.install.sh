#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="203570215"
MD5="c567026d954325b01f4afd51475850fd"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="STM STLink-Server installer"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="makeself_dir_CF037U"
filesizes="174080"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
    while true
    do
      MS_Printf "Please type y to accept, n otherwise: "
      read yn
      if test x"$yn" = xn; then
        keep=n
	eval $finish; exit 1
        break;
      elif test x"$yn" = xy; then
        break;
      fi
    done
  fi
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.3.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 524 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=y
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 176 KB
	echo Compression: none
	echo Date of packaging: Fri Jun  2 15:16:47 UTC 2023
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--nocomp\" \\
    \"--nox11\" \\
    \"--notemp\" \\
    \"/tmp/makeself_dir_CF037U\" \\
    \"st-stlink-server.2.1.1-1-linux-amd64.install.sh\" \\
    \"STM STLink-Server installer\" \\
    \"./setup.sh\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"makeself_dir_CF037U\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=none
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=176
	echo OLDSKIP=525
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 524 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "cat" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 524 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "cat" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 524 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 176; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "cat" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
./                                                                                                  0000700 0117457 0127674 00000000000 14436403737 010461  5                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 ./stlink-server                                                                                     0000755 0117457 0127674 00000442550 14436403737 013243  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 ELF          >           @       h<         @ 8 	 @ $ #       @       @       @       �      �                   8      8      8                                                         ��      ��                    P�      P�      P�             �                    p�      p�      p�                                 T      T      T      D       D              P�td    �       �       �                         Q�td                                                  R�td   P�      P�      P�      �      �             /lib64/ld-linux-x86-64.so.2          GNU                        GNU �^�
��1�B�}�#���   I         ��  DI   K   N   BE���|�qX���9�������                        �                     5                     :                     <                     �                     �                                            t                                          R                     <                     �                     V                      �                     l                     b                     {                     0                     �                     �                      u                                                               �                                          \                     �                      �                                                                �                      $                     �                                          �                     �                     -                       �                     -                     �                      �                     G                     m                     H                     �                     �                      �                     �                     �                     Z                     �                     �                     o                                                                �                     �                     �                     K                     4                     �                     �                     �                     �                     <                       �                     �                     �                     �  "                   n                     �                     f                     �    P !             �    � !             �    P !             �    �              U    � !            �     ��              N    ` !             libusb-1.0.so.0 _ITM_deregisterTMCloneTable __gmon_start__ _ITM_registerTMCloneTable libusb_release_interface libusb_get_device_descriptor libusb_get_configuration libusb_close _fini libusb_bulk_transfer libusb_get_device_list libusb_get_config_descriptor libusb_free_device_list libusb_get_string_descriptor_ascii libusb_open libusb_error_name libusb_get_device libusb_get_version libusb_claim_interface libusb_control_transfer libusb_hotplug_deregister_callback libusb_init libusb_set_configuration libusb_exit libusb_free_config_descriptor libpthread.so.0 send recv __errno_location accept sigaction libc.so.6 socket fflush strcpy htons sprintf fopen strncmp __isoc99_sscanf signal strncpy __stack_chk_fail listen select strdup strtok strlen getaddrinfo memset bind getnameinfo fputc inet_addr fputs strtok_r memcpy strtoul setsockopt malloc optarg stderr ioctl getopt_long usleep gettimeofday atoi __cxa_finalize freeaddrinfo strerror __libc_start_main vfprintf free _edata __bss_start _end GLIBC_2.2.5 GLIBC_2.7 GLIBC_2.14 GLIBC_2.4 /src/staging/libusb/linux64/lib                                                                                                                      ui	   �        \         ii   �     ���   �     ii        ui	   �      P�                    X�             �      `�             0�      p�             � !     ��             5�      ��             � !     ��             =�      ��             C�      ��             H�       �             R�      @�             M�      H�             U�      P�             ]�      X�             e�      `�             m�      h�             u�       !             !      !             !      !             !     0 !            0 !     8 !            0 !     @ !            @ !     H !            @ !     ��                    ��         !           ��         %           ��         A           ��         E           ` !        O           � !        M           ��                    ��                    ��                    ��                    ��                    ��                    ��                    ��         	           ��         
           ��                    ��                     �                    �                    �                    �                     �                    (�                    0�                    8�                    @�                    H�                    P�                    X�                    `�                    h�                    p�                    x�                    ��                    ��                    ��                    ��                     ��         "           ��         #           ��         $           ��         &           ��         '           ��         (           ��         )           ��         *           ��         +           ��         ,           ��         -           ��         .            �         /           �         0           �         1           �         2            �         3           (�         4           0�         5           8�         6           @�         7           H�         8           P�         9           X�         :           `�         ;           h�         <           p�         =           x�         >           ��         ?           ��         @           ��         B           ��         C           ��         D           ��         F           ��         G           ��         H           H��H��  H��t��H���         �5��  �%��  @ �%��  h    ������%��  h   ������%��  h   ������%��  h   �����%��  h   �����%��  h   �����%��  h   �����%��  h   �p����%��  h   �`����%z�  h	   �P����%r�  h
   �@����%j�  h   �0����%b�  h   � ����%Z�  h   �����%R�  h   � ����%J�  h   ������%B�  h   ������%:�  h   ������%2�  h   ������%*�  h   �����%"�  h   �����%�  h   �����%�  h   �����%
�  h   �p����%�  h   �`����%��  h   �P����%��  h   �@����%��  h   �0����%��  h   � ����%��  h   �����%��  h   � ����%��  h   ������%��  h    ������%��  h!   ������%��  h"   ������%��  h#   �����%��  h$   �����%��  h%   �����%��  h&   �����%��  h'   �p����%��  h(   �`����%z�  h)   �P����%r�  h*   �@����%j�  h+   �0����%b�  h,   � ����%Z�  h-   �����%R�  h.   � ����%J�  h/   ������%B�  h0   ������%:�  h1   ������%2�  h2   ������%*�  h3   �����%"�  h4   �����%�  h5   �����%�  h6   �����%
�  h7   �p����%�  h8   �`����%��  h9   �P����%��  h:   �@����%��  h;   �0����%��  h<   � ����%��  h=   �����%��  h>   � ����%��  h?   ������%��  h@   ������%��  hA   ������%��  hB   ������%��  f�        1�I��^H��H���PTL�J�  H�Ӌ  H�=�"  �~�  �D  H�=��  UH���  H9�H��tH�R�  H��t]��f.�     ]�@ f.�     H�=��  H�5��  UH)�H��H��H��H��?H�H��tH��  H��t]��f�     ]�@ f.�     �=��   u/H�=��   UH��tH�=
�  �����H����y�  ]��    ��fD  UH��]�f���UH��H�� �}�H�u�H�U�E���H�5O�  �   �    �  �E���t� H�=?�  ������Z  �L
  �E���������UH��H��   dH�%(   H�E�1�H��`�����   �    H������H�l���H��`����E�   H��`����    H�ƿ   �{�����\�����\��� y%��\�����H�5��  �    �    ��  �    �&��  ��~H�5��  �   �    ��  �   H�M�dH3%(   t�M�����UH��H�}�H�E�H� H9E���]�UH��}�H�E�    H���  H�E��/H�E�H�E�H�E�H�E��E�H9E�uH�E��"H�E�H�E�H� H�E�H�Q�  H9E�uĸ    ]�UH��J�  ��~H�5&�  �   �    �   ��  ��  �S�  �   ����UH��H��   dH�%(   H�E�1�Hǅ0���   ǅ���    ǅ���    ���  ����  H�5��  �   �    �  �  ������ƅ��� �    �   H��p���H����H����ʉ� �����$���ǅ���    H�[�  H��(����   H��(���H��P���H��P���H��X���H��X����@�P?��H�����Hc�H���p���H��X����@���Ѓ�?)к   ��H��H��H	�H��Hc�H���p��������H��(���H� H��(���H���  H9�(����c����$�  ��t6�%�  9����(���  ��~H�5��  �   �    �y  ƅ���H��0���H��`���Hǅh���    H��`���H��p���I�й    �    H�ƿ   �P������������� ��   ����� ����������t �������H�54�  �    �    ��  �)���  ��~�������H�5%�  �   �    �  ����� t�l����������  ���- �i����  ����� uB���  ��~ H��0���H��H�5�  �   �    �a  ����� �[  �
����Q  ����� t(�J�  ��~H�5ۇ  �   �    �   ���   H��  H��(�����  H��(���H��8���H��8���H��@�������� ��  H��@����@�P?��H���H�H���p���H��@����@���Ѓ�?)к   ��H��H��H!�H���r  �����H��@����@��t1���  ��~&H��@����@����H�5�  �   �    �I  H��@����@��tUH��@���H���  H���  ����� ��   ��  ��~H�5چ  �   �    ��  �    ��,  ��   H��@���H����  ��������������tH��@���H���  ������   H��@����@������H��@���H���,/  H��H���H��H��� tH��H����@$���h$  �
�    �b,  �c�  ��~H�G�  H�5H�  �   �    �2  H��@���H���'  �{���H��(���H� H��(���H��  H9�(��������H�=��  �1��������>����H�E�dH3%(   t�\�����UH��H�� �}�H�u�dH�%(   H�E�1��E�    H�U�H�u��E�I��H���  H�օ  ���2����E�}��u���  ���  �  �p�  ��~�E��H�5��  �   �    �A  �E��ht2��h��atF��dtn���  ��p�D  ��vt��l��   �  �x�     �  �m�     �z  ���  ��~H�5?�  �   �    ��  �`�  �M  ���  ��~5H���  H��t	H���  �H�
�  H��H�5�  �   �    �|  H���  H��t	H���  �H�Մ  H�������a�  ��   �V�  ��~ H���  H��H�5��  �   �    �"  H�j�  H����   ��  ��~ H�O�  H��H�5��  �   �    ��  H�/�  H����  �f���  ��~5H��  H��t	H��  �H�Y�  H��H�5T�  �   �    �  H���  H��t	H���  �H�$�  H���,  ������H�5�  ������    �L  H�5�  ������    �6  H�5.�  ������    �   H�5H�  ������    �
  H�5b�  ������    ��  H�5��  ������    ��  H�5ބ  ������    ��  ������U����?�  ��t�l  �    �<����    H�M�dH3%(   t�#�����UH��H�}�H�u�H�E�H�U�H�H�E�H�PH�E�H�PH�E�H�@H�U�H�H�E�H�U�H�P�]�UH��]�UH��H��H�}�H�E�H�������H���  ���UH��H��`H�}�H�u�dH�%(   H�E�1�H�E���H�U�H�E�H��jA�    A�    �.   H���W���H���E��}� t�E���H�5��  �   �    �  �H�E�H��H�5�  �   �    �  �H�E�dH3%(   t������UH��H��   dH�%(   H�E�1�H�E�   ƅu��� �E�    ���      �I�  ��~H�5��  �   �    �  �(�  ��~H�5��  �   �    ��  H�E��0   �    H�������E�   �E�   �E�   �E�   ���  ��~*H�y�  H�j�  H��H��H�5|�  �   �    �  H�O�  H��H�5z�  �   �    �w  H�/�  H�M�H�U�H�ƿ    �������t*�A���� �E��E���H�5H�  �    �    �2  �u  H�E�H��uH�5D�  �    �    �  �Q  ��  ��~H�5>�  �   �    ��  H�E�H�E��E�   �  ���  ��~-H�E�H�H �U�H�E�I�ȉ�H��H�52�  �   �    �  H�E��PH�E��HH�E��@�Ή��m����E��}��u@�_���� �E��E���H�5�  �    �    �P  H�5(�  �    �    �:  �a  �>�  ��~�E���H�55�  �   �    �  H���  H���_���f��v���f�E� ��v���������f�E�H�=�  �����E�H�E�   H������ǅx���   H��x����E�A�   H�Ѻ   �   ��������E��}��u-�t���� �E��E����5���H��H�5��  �    �    �]  ǅ|��� �  H��|����E�A�   H�Ѻ   �   �������E��}��u-����� �E��E��������H��H�5�  �    �    ��  H��|����E�A�   H�Ѻ   �   ���4����E��}��u-����� �E��E����w���H��H�5U�  �    �    �  H�E�H���E��   H�Ή��%�����tZ�l���� �E��}�buH�5B�  �   �    �\  �#�E�������H��H�5@�  �    �    �7  �E��������T  �1�  ��~H�5*�  �   �    �  �E��   ���w�����t/������ �E��E���H�=�  �    �����E����9�����   ���  ��~H�5��  �   �    �  H�U��E��!T  �Ǹ    ��������u%�q���� �E��E���H�5Ё  �    �    �b  ��  H�E�H�}� u"H�5ށ  �    �    �<  �E��������\H�E��U��PH�E��@H�E�H�5�  H���y������  ����  ƅu������  ��~H�5��  �   �    ��  H�E�H�@(H�E��E�H�}� ������H�E�H��t-H�E�H���������  ��~H�5p�  �   �    �  ���  ��~H�5��  �   �    �a  ��u���H�M�dH3%(   t�������UH��H�� �E�  ��~H�5i�  �   �    �  H��  H�E�H�E�H� H�E��   H�E�H�E�H�E�H�E����  ��~H�E��@��H�5<�  �   �    ��
  H�E��@���tCH�E��@���������  ��~H�E��@��H�5�  �   �    �
  H�E��@����H�E�H�E�H�E�H� H�E�H�\�  H9E��S������      �R�  ��~H�5�  �   �    �(
  ���UH��H���   H��H���dH�%(   H�E�1�ǅT����   Hǅh���    Hǅ`���   ǅX���    ���  ��~,H��H����@H��H���H�щ�H�5��  �   �    �	  H��p���H��H��H����@H��T���H�Ή�������\�����\����u>�Y���� ��X�����X��� t��X�����H�5a�  �    �    �;	  �    �	  ��T���Hc�H��p���H��H�������H��H����@H��`����!T  �Ǹ    �C������u+������ ��X�����X�����H�52~  �    �    ��  �:  H��h���H��h��� u%H�5:~  �    �    �  ��\�����������ZH��h�����\����PH��h����@ H��h���H�5_�  H��������a�  ��~��\�����H�5}  �   �    �/  H��h���H�M�dH3%(   t������UH��H�� H�}��E� H�E��� �  ��t!���  ��~H�5P  �   �    ��  H�E�H����  �    H�������H�E�H�pH�E�@�    ��  ���w����E��}� ya�y���� �E��}�u*���  ��~H�5  �   �    �^  �E� �   �}� t�E���H�5  �    �    �4  �E��s�}� uH�5  �    �    �  �E��QH�E苐$�  �E��H�E艐$�  H�E�ƀ �  �}�H�E�H���  H�E�H�PH�E�H�pH�E�A��H���c!  �E���UH��H���   H��8�����4���H��(���dH�%(   H�E�1�ƅC��� ǅH���    ǅL���    ǅD���    Hǅ`���    Hǅh���P�  ��  �    �   H��p���H����H����ʉ�P�����T���H��8����@�P?��H�����Hc�H���p���H��8����@���Ѓ�?)к   ��H��H��H	�H��Hc�H���p���H��8����@�xH��`���H��p���I�й    �    H��������X�����X��� �L  ��4���+�D�����H��8����@H��(����    ���;�����L�����L��� ��   �3���� ��\���ǅL���    ��\���t	��\���u\��\���u
�P�  �������H�����H�����  ��  ��~��\�����H�5}  �   �    ��  ƅC����[  ��\��� t)���  ��~��\�����H�5}  �   �    �  ƅC����  ��L��� u"H�5}  �    �    �g  ƅC�����   ��L����D�����L���H�H�(�����   ��X��� uA��H�����H�����   �'�  ��~H�5}  �   �    ��  ƅC����   ������ ��\�����\���uB��H�����H���~b���  ��~��\�����H�5�|  �   �    �  ƅC����0���  ��~��\�����H�5�|  �   �    �p  ƅC�����D���;�4���s��C�������������D���H�M�dH3%(   t������UH��H�� H�}��E� H�E��� �  ����uH�E苀�  ��*��  ���S  H�5�|  �   �    ��  �8  H�E苀�  Hc�H�E�H�HH�E苀�  ��H�4H�E�@�    ���j����E��}��uS�|���� �E��}�uH�5:|  �    �    �l  �E� ��   �E���H�5N|  �    �    �H  �E��   H�E苐�  �E��H�E艐�  H�E苀�  +E���H�E艐�  H�E苀�  ��uH�E�ƀ �   H�E苐(�  �E��H�E艐(�  H�E苀�  ��t2���  ��~'H�E苐�  �E��щ�H�5�{  �   �    �  �E���UH��H��0dH�%(   H�E�1�H�E�    H���l����Eԃ}� y�E�H�H�E��7H�E�Hi��  H�M�H���S㥛� H��H��H��H��H��?H)�H��H�H�E�H�E�H�}�dH3<%(   t������UH��H���   ��,���H�� ���H��`���H��h���L��p���L��x�����t )E�)M�)U�)]�)e�)m�)u�)}�dH�%(   H��H���1��/�  ���&�  ���  9�,���gǅ0���   ǅ4���0   H�EH��8���H��P���H��@�����,����u2H���  H��0���H�� ���H��H���Z���H���  H���[�����H��H���dH3%(   t������UH��H���   �����H�����H��`���H��h���L��p���L��x�����t )E�)M�)U�)]�)e�)m�)u�)}�dH�%(   H��H���1��'�  ����  ���  9�����J  ǅ0���   ǅ4���0   H�EH��8���H��P���H��@����Q�  ����   ������H���  )Љ�,������  �����H�H��    H�3�  H�H���  ��,���A��H�5Uy  H�Ǹ    ����H�\�  H��0���H�����H��H�������H�<�  H�ƿ
   �7����j����� x-�����H�H��    H���  H�H��  H��H������H���  H��0���H�����H��H������H���  H�ƿ
   �����H���  H���l�����H��H���dH3%(   t������UH����     H�k�  H�|�  �[���H�x�  �]�UH��H�� H�}�H�E�H�5Fx  H�������H�E�H�}� tH�E�H�8�  �    ��UH��H��pH�}�H�u�H�U�dH�%(   H�E�1�H�v2.1.1-1H�E��E� H�E�    H�E�    H�E�    H�U�H�E�H�5�w  H�������H�E�H�}� t!H�E�H�E�H��H�5�w  �    �����H�E�H�}� tH�E�H��H�5�w  �    ����H�E�H�}� tH�U�H�E�H�5bw  H������H�}� �'  H�}� �  H�}� �  H�E��
   �    H�������H�E�H�E��
   �    H�������H�E�H�EȺ
   �    H������H�E��s�  ��~-H�E���H�E؉�H�E�A�ȉщ�H�5�v  �   �    �2��������H9E�w<�����H9E�w1�����H9E�w&H�E�H�U�H�H�E�H�U�H�H�E�H�U�H��   H�E�H�     H�E�H�     H�E�H�     ���  ��~\H�5Wv  �   �    �����DH�E�H�     H�E�H�     H�E�H�     ���  ��~H�5<v  �   �    �e������H�E�dH3%(   t�������UH��H�� dH�%(   H�E�1�H�E�    H�E�    H�E�    H�U�H�M�H�E�H��H���[���H�M�H�U�H�E�H��H�=�u  �    ������H�E�dH3%(   t�_�����UH��H�� �}�H�u��E�    ����H�=�u  �a����   �   �g������  ��~H�5�u  �   �    �w������������tH�5�u  �    �    �U���H�U��E�H�։��y����M�  ��~H�5�u  �   �    �#�����������   �K  ��t"H�5uu  �    �    ������E������   ��  ��  ��~H�5ku  �   �    ����������ɾ  ��~H�5^u  �   �    �����V������  ��~H�5Ru  �   �    �y����`  ��E������E���UH��H�}�H�E�H� H�U�H�RH�PH�E�H�@H�U�H�H�H�E�H�     H�E�H�@    �]�UH��H�}�H�u��E�    �E��E��)�U�H�E�H�� ��E��E���
E��E���1E��E��E�H9E�w΋E���E��E���1E��E���E��E�]�UH��H�� H�}�H�E�H���	���H��H�E�H��H���i�����H�E�H�E����p   H��u�    ��   ��UH��H��H�}��a�  ��~+H�E�H�PH�E�H� H��H��H�5t  �   �    �"���H�E�H������H�E�H����������UH��H��0�}�H�$�  H�E��dH�E�H�E�H�E�H�E���  ��~,H�E��H4H�U��E�A��H�щ�H�5�s  �   �    ����H�E��@49E�uH�E��CH�E�H� H�E�H���  H9E�u����  ��~�E܉�H�5�s  �   �    �X����    ��UH��H��0H�}�H�E�H������H��H�E�H��H��������H�E�H�I�  H�E��aH�E�H�E�H�E�H�E���  ��~&H�E��P4H�E���H��H�5As  �   �    �����H�E��@4��H9E�uH�E��EH�E�H� H�E�H�ۻ  H9E�u����  ��~H�E�H��H�5s  �   �    �~����    ��UH��}��E�    H���  H�E��-H�E�H�E�H�E�H�E��E�;E�uH�E��!�E�H�E�H� H�E�H�W�  H9E�uƸ    ]�UH��H�=?�  ��  ]�UH��H�� �}�H�u��E���y���H�E�H�}� ��   ��  ��~"H�U��E�H�щ�H�5jr  �   �    ����H�E�H�@H�U�H��H��H�������H�E��P*H�E�f�P&H�E��P(H�E�f�P$H�E��@( H�E�H�@H�������H��H�E�H�@H��H���,�����H�E��P4�K�  ��~7H�E�H�HH�E��@&��H�E��@4I�ȉщ�H�5�q  �   �    � ���H�E��P4H�E���   � �E��H�5�q  �    �    ������  ��UH��H���}�H�u�H�U��E�H�։�����H��uH�E�� ��    ��UH��H��0�}�H�uЋE܉��u���H�E�H�}� �  �v�  ��~+H�EЋ�0�  H�E��@4�щ�H�5�q  �   �    �7���H�U�H�E�H��H���  H�E�H�E�H�@H�@H���a  H�}� �V  H�E�H���1S  �E���  ��~8H�E�H�@H�HH�E�H�@H� �U�I�ȉ�H��H�5Lq  �   �    �����}� ��   H�E�H���6=  �E�}� u/���  ���b  �E܉�H�5Sq  �   �    �e����B  �i�  ��~�E��H�5Cq  �   �    �:���H�E�H�@H�@    H�E�H������H�E�H�������H�E�    ��   ��  ��~�E܉�H�5q  �   �    �����H�E�H�@H�@    H�E�H���]���H�E�H������H�E�    �   H�}� u#���  ��~{H�5�p  �   �    �����c���  ��~XH�E�H�@H�@H��H�5�p  �   �    �P����1�W�  ��~�E܉�H�5�p  �   �    �(���H�E�    ��H�E���UH���R  �]�UH����D  H�]�UH��H�� �}�E���8
  H�E�H�}� tH�E�H�@H�@�U��H���n6  �H�5�p  �    �    �������  ��~�E��H�5�p  �   �    �����E����  H���UH��H��P�}�H�u�H�U�H�M�L�E��E܉��	  H�E��E�    H�}� t+H�E��@ ��tH�E�H�@H�@H�E��}� ��   ��   H�}� t:H�E��@ ����t+H�E��@$��H�5p  �    �    �����H�������   H�}� t!H�E��@$��H�5&p  �    �    �����H�5�o  �    �    ����H�������rH�EЋ ��u!H�EЋ@��H�M�H�E�H��H���s/  �E��CH�E�H�HH�E�H�PH� H�H�QH�EЋ ��H�EЋ@��H�u�H�E��щ�H���N-  �E�E���UH��H�}�H�E�    H�E�H� H�E��H�E�H�E�H� H�E�H�E�H;E�u�H�E�]�UH��H�}�H�E�H� H�U�H�RH�PH�E�H�@H�U�H�H�H�E�H�     H�E�H�@    �]�UH��H�=��  �l���]�UH��H���h�  ����H�E�H�}� u'�q�  ����   H�5�n  �   �    �C����s�J�  ��~H�E�H��H�5�n  �   �    ����H�E��h�  �    H���2���H�E��@�������  �����  �~�  H�E���0�  H�E�ƀ �   H�E���UH��H��H�}�H�E�H���������  ��~H�E�H��H�5jn  �   �    ��������UH��H��H�}����  ��~+H�E�H�PH�E�H� H��H��H�5@n  �   �    �B���H�E�H���X���H�E�H���b������UH��H�}�H�u�H�E�H�U�H�H�E�H�PH�E�H�PH�E�H�@H�U�H�H�E�H�U�H�P�]�UH��H�}�H�E�H� H�U�H�RH�PH�E�H�@H�U�H�H�H�E�H�     H�E�H�@    �]�UH��}��E�    H���  H�E��;H�E�H�E�H�E�H�E�H�E��@ ��tH�E�H�@�@49E�u�E�H�E�H� H�E�H�]�  H9E�u��E�]�UH��H��0�}�H�@�  H�E��nH�E�H�E�H�E�H�E�H�E��@ ��tGH�E�H�@�@49E�u7���  ��~$H�E��@$�U܉щ�H�5�l  �   �    �����H�E��@  H�E�H� H�E�H�ű  H9E�u����UH���E�    H���  H�E���E�H�E�H� H�E�H���  H9E�u�E�]�UH��m�  �P�d�  ]�UH��H�� H�}�H�u�(   �d���H�E�H�}� trH�E�H�U�H�PH�E�H�U�H�P������H�E��P$H�E��@ ��  ��~$H�U�H�E�H��H��H�5Cl  �   �    �����H�E�H�5�  H�������/���  ��~$H�U�H�E�H��H��H�5?l  �   �    ����H�E���UH��H��@H�}�H�u��E� H�E�    H��  H�x�  H9�t{H�l�  H�E��_H�E�H�E�H�E�H�E�H�E��@ ��t8H�EȋP4H�E�H�@�@49�u"H�E���0�  H�E�H�@��0�  9�u�E��H�E�H� H�E�H� �  H9E�u���E� �E߃�����   �ϯ  ��~"H�E���0�  ��H�5�k  �   �    ����H�U�H�E�H��H���7���H�E�H�E�H�E�H�}� tu�|�  ��~jH�E��@$H�U�H�щ�H�5Pk  �   �    �B����B�I�  ��~H�E��@$��H�5Gk  �   �    ����H�E�H�U�H�PH�E�H�U�H�PH�E���UH��H���}����  ��t�@���9E�u	�I�  �(�خ  ��~�"�����H�5�j  �   �    ������  ��UH��H��0�}܋��  ��~�E܉�H�5�j  �   �    �m����E܉��  H�E�H�}� ��  �E܉��  H�E��@ ���  H�E�H�@�@4�������E�.�  ��~(H�E�H�@�@4�U�щ�H�5�j  �   �    ������}��  ��  ��~&H�E��@$H�U�H�щ�H�5�j  �   �    ����H�E�H�@H�E����  ��~!H�E�H�@H��H�5�j  �   �    ����H�E�H�@H���d1  H�E��@8 �p�  ��~������H�5�j  �   �    �?���H�E�H�@H�@    �   �-����S�,�  ��~H�5hj  �   �    ������  ��~�U�����H�5+j  �   �    ������   �����H�E�H�������H�E�H�������    ��UH��}�H�¬  H�E��-H�E�H�E�H�E�H�E�H�E��@$9E�uH�E��H�E�H� H�E�H���  H9E�uƸ    ]�UH��H�}�H�l�  H�E��=H�E�H�E�H�E�H�E�H�E؋�0�  H�E�H�@��0�  9�uH�E��H�E�H� H�E�H�"�  H9E�u��    ]�UH��}��E�    H� �  H�E��;H�E�H�E�H�E�H�E�H�E��@ ��tH�E�H�@�@49E�u�E�H�E�H� H�E�H���  H9E�u��E�]�UH��H�}��u�E�����H�E�H����E�����H�E�H����E�����H�E�H����E��H�E���]�UH��}��ի  9E�u
�ƫ      �]�UH��}�E�=�   ��   =�   A����   ����tl��t{���tl�=�   tm=�   -�   ��wg�Z=�   tS�\=U  =Q  }C-   ��wD�7= P  t0= P  -    ��w*�=   t�H�E�   �H�E�   ��E�H�H�E��	H�E�   �H�E�]�UH��AVAUATSH���  H��(���H�� ���H�����H�����D�����dH�%(   H�E�1�ǅ@���    H�� ���� ����   �����t2������   ��H�5�g  �    �    �����H������    �O������@�����@�����������H���������  ��~!H������ ��H�5lg  �   �    �n���H������    �!  H�� ���� <��   �����t2������   ��H�5Dg  �    �    ����H������     �@�������H��������  ��~%H������ ����H�55g  �   �    �����H������    �w   H�� ���� <��   �����t2������   ��H�5g  �    �    ����H������     �`H�� ����@���������������]�����H�������Q�  ��~-H������ ���������щ�H�5�f  �   �    ����H������    �  H�� ���� <�?  H�� ����@��D�����  ��~1H�� ���H��� ����D����щ�H�5�f  �   �    ���������t/������   ��H�5�f  �    �    �t���ǅ@���   �(H�� ���H��� ��H������H�։��=�����@���H�������@������D����PH��������D���)vA��D���H�����H�JH�¾    H���$�����@���uH������ R  ǅD���)   ��D���H�����H�HH������H��H�������g  H�� ���� <��  �����tL�����tC������   ��H�5f  �    �    �f���H�����H���     ǅ@���   �  ǅ@���   H�� ����@������H�� ���H��� ������?�����  ��~7H��(�����0�  ��?���������A�ȉщ�H�5�e  �   �    �����H��(���������H�։��%���H��X���H��X��� u3H�5�e  �    �    ����ǅ@���  H�����H���     �N��  ��~"H��X����@$��H�5�e  �   �    �I���ǅ@���   H�����H�PH��X����@$�H�������@����H������    ��  H�� ���� <��   �����t/������   ��H�5Oe  �    �    �����ǅ@���   �PH�� ����@��|������  ��~��|�����H�5Je  �   �    ������|����������ǅ@���   ��@������@�����H������H������    ��  H�� ���� <�L  ǅ@���   �����w:������    ��H�5�d  �    �    �����ǅ@���   H������    ��@�����  H�� ���H��H��8���H��8���� ��H������  ���  H�� ���H��� D��H�� ���H��� ��H�� ���H��� D��H�� ���H��� D��H�� ���H��� D��H�� ���H��� D��H�� ���H��� ��H�� ���H��� ��H�� ���H��� ��H�� ���H��
� D��H�� ���H��	� D��H�� ���H��� �Ћ�H���H��ATSASARAQAPWVQE��E��щ�H�5�c  �   �    ����H��PH�� ���H��H������H������H��@���H�� ���H��H��H���H��(�����0�  H��H����H�� ���H��� ����`���H�� ����@��d���H�� ���H�� H��������`�����uhH������    �	�  ��~�������H�5�c  �   �    �������  ����   ��d�����H�5|c  �   �    �����   ��`�����u&H�����H��H��������d����PH�������P��`�����uEH�����H��H��������d����PH�������N�  ��~H�5c  �   �    �$�����@����Y  ��`������  �����H�� ���H�H��P����������L�����d����� ��p���ǅt���    ��L���;�p�����   ��p��� �  v%��p���� �  ��H�5�b  �    �    �����8��p���+�L�����H��P���H��(�����H��������t�����t����L�����L���;�p�����   ��p�����L����щ�H�5Hb  �    �    ����ǅ@���   H������    �C����� t:������    ��H�5Kb  �    �    �����ǅ@���   H������    ��@�����   H�� ���H��� <�uCH�� ���H��	� <Qu1�*�  ��u��H�����  �nǅ@���   H������    �UH�� ���H��� <�uCH�� ���H��	� <Ru1�՟  9�H���u�ß      �ǅ@���   H������    ��@�����  H������H������H��`�����H���A��  ���Y�����@�����@��� t)�̞  ��~��@�����H�5Pa  �   �    ����H�����H��H��@������  ���w  H������ ���e  H������ ����x�����x�����  ��x����  �D�  ���*  H��@���H��� D��H��@���H��
� ��H��@���H��	� D��H��@���H��� D��H��@���H��� D��H��@���H��� D��H��@���H��� ��H��@���H��� ��H��@���H��� ��H��@���H��� D��H��@���H��� D��H��@���� �Ћ�d���H��ATSASARAQAPWVQE��E��щ�H�5`  �   �    �%���H��P�  �%�  ���  H��@���H��� D��H��@���H��� D��H��@���H��� ��H��@���H��� ��H��@���H��� ��H��@���H��� D��H��@���H��� D��H��@���� �Ћ�d���H��AQAPWVQE��E�Љщ�H�5�_  �   �    �T���H��0�L�W�  ��~AH��@���H��� ��H��@���� �Ћ�d���A�ȉщ�H�5�_  �   �    ������@������������H�������  H�� ���� <�  ƅ=��������t#������   ��H�5V_  �    �    ����H�� ����@��>������  ��~(��=�����>����щ�H�5b_  �   �    �\���H������     H������ H��`���H������H������H��H���{���H��������H�����H����H���y���H��������H�����H����H���[���H��`�����H�����H����H���=���H������    �s  H�� ����   H�5�^  H��轳������   ���  ��~&H��(���H4�  H��H�5�^  �   �    �e����E�����H�E�H�5�^  H�Ǹ    �Ŷ���O�  ��~+H��(���H��4�  H�E�H��H�5�^  �   �    ����H�U�H�����H��H���)���H�E�H���]�����H�������  H�� ����   H�5|^  H���������`  �E�    �E� H�� ���H��0���ǅP���    H�U�H��0���H��H��衵��H�������~H��������P���Hc�H��H��H�H��H�H�������P   H��H���P�����P���Hc�H��H��H�H��H�]�H�H-�  �  H�E�H�ƿ    �(���H��������P���H������ t��P����k�����  ��~&H��(���H4�  H��H�5�]  �   �    ����H������H��PH���������H��p���H�Ɖ��������l�����l��� ��   ����������������H��p���H�x��l���H�E�I��A��H�5>]  H�Ǹ    趴���@�  ��~+H��(���H��4�  H�E�H��H�5]  �   �    �����
�  ��~iH��p���H��H��H�5"]  �   �    ������C�ٗ  ��~+H������H��PH��������H�5�\  �   �    ����H�E�f� 0
�@ H�U�H�����H��H��覰��H�E�H���ڰ����H�������  H�� ����   H�5�\  H���_������v  �E�    �E� H�� ���H�� ���ǅT���    H�U�H�� ���H��H������H�������~H��������T���Hc�H��H��H�H��H�H�������P   H��H���ͯ����T���Hc�H��H��H�H��H�]�H�H-�  �  H�E�H�ƿ    襲��H��������T���H������ t��T����k���H��`���H������H�JPH��H�5�[  H�ϸ    藱���A�  ��~<H��(�����0�  ��`���H��(���H��4�  A�ȉ�H�5w[  �   �    �������`�����H��(���H�Ɖ��C���H��(���H��(��� t_�Е  ��~0H��(����@$H��(���H��4�  ��H�5J[  �   �    ����H��(����P$H�E�H�5�Y  H�Ǹ    �����>�q�  ��~&H��(���H4�  H��H�5%[  �   �    �7���H�E�f� 0
�@ �3�  ��~+H��(���H��4�  H�E�H��H�5[  �   �    �����H�U�H�����H��H������H�E�H���A�����H�������|  H�� ����   H�5�Z  H���ƭ������  �E�    �E� H�� ���H�����ǅX���    H�U�H�����H��H��腰��H�������~H��������X���Hc�H��H��H�H��H�H�������P   H��H���4�����X���Hc�H��H��H�H��H�]�H�H-�  �  H�E�H�ƿ    ����H��������X���H������ t��X����k���H��`���H������H�JPH��H�5�Y  H�ϸ    ��������  ��~,��`���H��(���H��4�  ��H�5�Y  �   �    �h�����`������]�����@�����@��� uEH�E�f� 1
�@ �H�  ��~:H��(���H��4�  H�E�H��H�5�Y  �   �    �	����H�E�f� 0
�@ H�U�H�����H��H������H�E�H���G�����H�������
  H�� ����   H�5QY  H���̫������  �E�    �E� H�� ���H�� ���ǅ\���    H�U�H�� ���H��H��苮��H�������~H��������\���Hc�H��H��H�H��H�H�������P   H��H���:�����\���Hc�H��H��H�H��H�]�H�H-�  �  H�E�H�ƿ    ����H��������\���H������ t��\����k���H������H������H�JPH��H�5�W  H�ϸ    �����������������H�����H����� �  H������@ ����  H�����H�@H�@H����  �a�  ��~ H�����H��H�5�W  �   �    �-����6�  ��~&H��(���H4�  H��H�5�W  �   �    �������������H�����H�@H�@H��`�����H����  ��@���H�����H�@H�@H�����H������@^f=K7tH������@^f=R7uH�E�� 2.1 �   H������@^f=N7t3H������@^f=O7t"H������@^f=S7tH������@^f=T7uH�E�f� 3 �SH������@^f=H7uH�E�f� 2 �7H������@^f=V7tH������@^f=W7uH�E�� PWR �	H�E�f� ? H������@^D��H������@\����c�������b���D����`���D��H�M���@���H�E�H��APWVE��H�5�V  H�Ǹ    �����H�� �H�E�f� 0
�@ �q�  ��~+H��(���H��4�  H�E�H��H�5XV  �   �    �2���H�U�H�����H��H���K���H�E�H��������H�������  H�� ����   H�52V  H����������  �E�    �E� H�� ���H������ǅ`���    H�U�H������H��H���ê��H�������~H��������`���Hc�H��H��H�H��H�H�������P   H��H���r�����`���Hc�H��H��H�H��H�]�H�H-�  �  H�E�H�ƿ    �J���H��������`���H������ t��`����k�����  ��~&H��(���H4�  H��H�5;U  �   �    ������������@�����@���H�E�H�53R  H�Ǹ    �+������  ��~+H��(���H��4�  H�E�H��H�5U  �   �    �v���H�U�H�����H��H��菦��H�E�H���æ����H��������  H�� ����   H�5�T  H���H������P  �E�    �E� H�� ���H������ǅd���    H�U�H������H��H������H�������~H��������d���Hc�H��H��H�H��H�H�������P   H��H��趥����d���Hc�H��H��H�H��H�]�H�H-�  �  H�E�H�ƿ    莨��H��������d���H������ t��d����k���H��`���H������H�JPH��H�5bR  H�ϸ    耧���*�  ��~&H��(���H4�  H��H�5�S  �   �    �������`������l���H������H������ ��   H������H�@H��tx�ǋ  ��~*H�������P4��`����щ�H�5�S  �   �    ������`�����H������H�@��H���  ��@�����@���H�E�H�5�O  H�Ǹ    �ǧ���H�E�f� 0
�@ �B�  ��~+H��(���H��4�  H�E�H��H�5!S  �   �    ����H�U�H�����H��H������H�E�H���P�����H�������  H�� ����   H�5�R  H���գ������  �E�    �E� H�� ���H������ǅh���    H�U�H������H��H��蔦��H�������~H��������h���Hc�H��H��H�H��H�H�������P   H��H���C�����h���Hc�H��H��H�H��H�]�H�H-�  �  H�E�H�ƿ    ����H��������h���H������ t��h����k���H��(���H4�  H������H��PH��H������H������H��PH������H�P�H��(�����4�  <
u&H������H��PH������H�P�H��(���Ƅ4�   H�E�f� 1
�@ �`�  ��~+H��(���H��4�  H�E�H��H�5Q  �   �    �!���H�U�H�����H��H���:���H�E�H���n�����H�������   ���  ��~ H�� ���H��H�5RQ  �   �    �����H�E�H�0 unknowH�n_commanH�H�pf�@d
�@ ���  ��~H�E�H��H�5)Q  �   �    �s���H�U�H�����H��H��茡��H�E�H���������H�������H�E�dH3%(   t�����H�e�[A\A]A^]�UH��H�}��u�E�����H�E�H����E�����H�E�H����E�����H�E�H����E��H�E���]�UH��H��0H�}�H�u��U܉ȈE��E�   �E�    H�}� u H�5xP  �    �    ����������  H�E�H�@H��u H�5sP  �    �    �e���������d  H�E�H�xH�E��@��H�E�H�@�U�A��  ��H��H���.  9E�t(�.�  ��~H�5AP  �   �    �����E������}� ��   �}� ��   �}� u^H�E��@��H�E�H�@�M�H�U�A��  H���-.  9E���   ���  ��~H�5�O  �   �    �����E������   �}�uWH�E��@��H�E�H�@�M�H�U�A��  H����-  9E�tX�[�  ��~H�5�O  �   �    �1����E������.�1�  ��~�E؉�H�5�O  �   �    �����E������E���UH��H�� H�}�H�u��U�H�}� u H�5�O  �    �    �����������   H�E�H�@H��uH�5�O  �    �    ����������ZH�E��@��H�E�H�@�M�H�U�A��  H����,  9E�t(�m�  ��~H�5O  �   �    �C����������    ��UH��H��H�}�H�E�H���    �    H���>���H�E�H��;�    �    H���$������UH��H��0H�}�u�H�U�H�}� u H�5 O  �    �    �¿���������  H�E�H���w����E�H�E��@^f=K7t H�E��@^f=R7tH�E��@^f=H7�|  H�E��@�E�H�U�H��'��H���9����U�H�E�H�p;H�E�Ѻ   H���i����E��}� t�E��X  H�E��@;����H�E؈H�E��@;������<��H�E��@<��	Љ�H�E؈PH�E��@<��?��H�E؈PH�E��@ H�E��@ H�E��@ H�E��@>������H�E��@=��	Љ�H�E�f�P\H�E��@@������H�E��@?��	Љ�H�E�f�P^H�E��@^f=H7�k  H�E��@<v?H�E��@<w3H�E��@<t'H�E��@<tH�5�M  �    �    �����   H�E��PH�E؈PH�E��@ �  H�E��@��E�H�U�H��'��H�������U�H�E�H�p;H�E�Ѻ   H��������E��}� t�E���   H�E��P;H�E؈H�E��P<H�E؈PH�E��P=H�E؈PH�E��P>H�E؈PH�E��P?H�E؈PH�E��P@H�E؈PH�E��@ H�E��@ H�E��@D������H�E��@C��	Љ�H�E�f�P\H�E��@F������H�E��@E��	Љ�H�E�f�P^H�E��P\H�E�f�PH�E��P^H�E�f�P
�    ��UH��H��0H�}�H�u��U�H�}� u H�5iL  �    �    裼��������   H�E�H���X���H�E��@��E�H�U�H��'��H���L���H�E�H�p;H�E�   �   H���}����E��}� uH�E��P;H�E���D�  ��~'H�E�� �ЋE��щ�H�5�K  �   �    �	����E���UH��H�� H�}�u�H�}� uH�5L  �    �    �ػ��������xH�E�H������H�E��@�H�E��@!�E�H�U�H��'��H���|���H�E�   �    �    H�������E����  ��~�E���H�5�K  �   �    �\����E���UH��H�� H�}�u�dH�%(   H�E�1�H�}� u H�5�K  �    �    �����������   �U�H�M�H�E�H��H���)����E�}� t�E���   ��  ��~�E�����H�5uK  �   �    ������E�<��   �U�H�E��H�������E��  ��~�E��H�5�J  �   �    �{����}� t�E��F�U�H�M�H�E�H��H�������E�`  ��~�E�����H�5�J  �   �    �-����E�H�M�dH3%(   t襘����UH��H�� H�}�u�H�}� uH�5�J  �    �    ����������xH�E�H������H�E��@�H�E��@�E�H�U�H��'��H������H�E�   �    �    H��������E���~  ��~�E���H�5jJ  �   �    �l����E���UH��H�� H�}�u�dH�%(   H�E�1�H�}� u H�5RJ  �    �    �,���������   �U�H�M�H�E�H��H���9����E�}� t�E��   �~  ��~�E�����H�5�I  �   �    �Ѹ���E��ub�U�H�E��H�������E�}� t�E��F�U�H�M�H�E�H��H��������E��}  ��~�E�����H�5I  �   �    �g����E�H�M�dH3%(   t�ߖ����UH��H�� H�}�u�H�}� u H�5xI  �    �    �"���������  H�E��@`<w H�E��@`<��   H�E��@a<��   �U�H�E��H���t����E��}� t�E��   H�E�H������H�E��@�H�E��@I�E�H�U�H��'��H���u���H�E�H�p;H�E�   �   H�������E���|  ��~�E���H�5�H  �   �    �R����}� t�E��:�    �3�I|  ��~#H�E��@a����H�5�H  �   �    �����   ��UH��H��H�}�H�}� ��   H�E�H�@H��t~��{  ��~H�5�H  �   �    �ƶ��H�E�H�@�    H���0�����{  ��~!H�E�H�@H��H�5�H  �   �    腶��H�E�H�@H���d���H�E�H�@    �    ��UH��H��@H�}�dH�%(   H�E�1�H�E�H�@H�E�H�}� uH�54H  �    �    �����v  H�E�H�@H��uH�5LH  �    �    ������N  H�E��P*H�E�f�P^��z  ��~!H�E�H�@H��H�5SH  �   �    赵��H�E�H�@�    H���
  H�E�H�pH�E�H�HH�E�H�PH�E�H�@I��H�ƿ    �  �E܃}� tH�5'H  �    �    �Q����  H�U�H�E�    H���E����E܃}� �w  H�E��@^f=H7uEH�E��@^���E����E����E���A��A�ȉщ�H�5�G  �   �    �ܴ���  H�E��@^f=K7tH�E��@^f=R7uEH�E��@^���E����E����E���A��A�ȉщ�H�5�G  �   �    �{����  H�E��@^f=N7tH�E��@^f=T7uEH�E��@^���E����E����E���A��A�ȉщ�H�5`G  �   �    �����E  H�E��@^f=S7tH�E��@^f=O7uZH�E��@^���E����E�D���E����E����E���VQE��A���щ�H�5G  �   �    訳��H����   H�E��@^f=V7tH�E��@^f=W7uWH�E��@^���E����E�D���E����E����E���VQE��A���щ�H�5�F  �   �    �2���H���\H�E��@^���E����E����E�D���E�D���E����E���H��WVQ�щ�H�5�F  �   �    �Բ��H�� �U�H�E��P`�U�H�E��Pa�    �MH�E��@`H�E��@a��w  ��~!H�E�H�@H��H�5]F  �   �    �w���H�E�H���`��������H�M�dH3%(   t������UH��H�}�H�u�H�E�H�H�E�H�H�E�H�U�H�PH�E�H� H�U�H�PH�E�H�U�H��]�UH��H�}�H�u�H�E�H�U�H�H�E�H�PH�E�H�PH�E�H�@H�U�H�H�E�H�U�H�P�]�UH��H�}�H�E�H� H�U�H�RH�PH�E�H�@H�U�H�H�H�E�H�     H�E�H�@    �]�UH��H��H�}�H�u�H�E�H� H�U�H�RH�PH�E�H�@H�U�H�H�H�U�H�E�H��H����������UH��H�� H�}���H�M�D�E��U�f�E��E����u��E����H�}�H�E�h�  QI��A���Ѻ   ��   H���J���H����UH��H�� H�}�H�u�H�E�� ���E��}�uR�E�    �A�E����Hc�H�E�H�� ���U��Hc�H�U�Hщ�H�5�D  H�ϸ    �����E��}�~��=�}�2u7�E�    �(�E����Hc�H�E�H���E�Hc�H�E�HȈ�E��}�~�H�E�H���  �    ��UH��H��@H�}�H�u�dH�%(   H�E�1�H�U�H�E�H��H��辐���E܃}� uP�E�    �/�E�f=�u!�U�E�H� H�E�H�� f9�u�   �T�E��E�H� H�E�H�� f��u��3��t  ��~(�E܉������H�E܉�H�5�C  �   �    �S����    H�M�dH3%(   t�ɍ����UH��H�� H�}�H�u��U�H�M��}�u/�$t  ��~H�E�H��H�5]C  �   �    �����׼���W�}�u6��s  ��~H�E�H��H�5:C  �   �    辮��H�E�H����   ��E��H�5%C  �    �    蕮���    ��UH��H��H�=&t  �I�����y
������   ����H�E�H�}� ti�es  ��~H�E�H�HH�E��@��H�E��@��H�E��@��H�E�� ��H��QA��A���щ�H�5�B  �   �    �����H���!��r  ��~H�5�B  �   �    �ҭ���    ��UH��H��   H��x���dH�%(   H�E�1�H�U�H��x���H��H���s���H��x���H�5�A  H���m�����uUH�U�H��x���H��H���c����E���H�E�H�U��@   H���g���H�E�H������H�E�H�}� tH�E�H��������   H�M�dH3%(   t蛋����UH��H��   dH�%(   H�E�1�ƅ���� ǅ����    H�r  H������  H�����H��@���H��@���H��H�����q  ��~,H��H����P4H��H�����H��H�5gA  �   �    �y���H��H����@9 H��H���H�@H�@H����   �_q  ��~$H��H���H�@H��H�5EA  �   �    �'����0q  ��~(H��H���H�@H�@H��H�5:A  �   �    �����H��H���H�@H�@H���̊��H��H���H�@H�@    H��H����@;H�����H� H�����H��p  H9���������H�:q  H������H��H��萋����������p  ��~��������H�5�@  �   �    �R���ǅ����    �p  H������������Hc�H��H�H� H��P���H��H������������������� tN�p  ���  ���������;���H�Ƌ�����������A�Љ�H��H�5U@  �   �    迪����  H������������Hc�H��H�H� H�5�>  H��������uK��o  ����  ��Z�������X����Ћ�����A�ȉщ�H�5%@  �   �    �G����g  H������������Hc�H��H�H� H�� ���H��H������������������ �f  ��`�����H�� ���H�U�A�@   H�Ѻ	  H��������y=��n  ��~��������H�5�?  �   �    諩��H�� ���H��苈���  H��p���H�E�H��H��������n  ��~ H��p���H��H�5�?  �   �    �V���H��p���H��蕰�������K  �@   �a���H��8���H��8��� ty�h   �F���H��H��8���H�PH��8���H�@H��unH�5A?  �    �    ����H��8���H�@H��tH��8���H�@H��菆��H��8���H��耆��ƅ�����H�5�>  �    �    蒨��ƅ���������������B  H��8���H�H H��P����   H��H���V���H������������Hc�H��H�H��8���H�@H�H�H��p���H���ω��H��H��8���H�PH��8���H�@H�� ���H�PH��8����@8 H��8����@9��l  ��~EH��8����@*��H��8����@(��H��8���H�@A�ȉ�H��H�5$>  �   �    薧����l  ��~9H��8���H�@H�PH��8���H�@H� H��H��H�5 >  �   �    �R���H��8���H�5sl  H���/����]  �@l  ��~ H��p���H��H�5
>  �   �    ����H�� ���H������ƅ���� �  ��k  ��~ H��p���H��H�5�=  �   �    �Ʀ��H��p���H���f���H��8���H��8��� ��  ��k  ��~YH��8���H�@H�pH��8���H�@H�H��8����@*��H��8����@(��I��I�ȉщ�H�5�=  �   �    �>���H��8����@9H������������Hc�H��H�H��8���H�@H�H�H��8���H�@H�� ���H�PH��8����@8 ��j  ���  H��8���H�@H�PH��8���H�@H� H��H��H�5P=  �   �    袥����   H��p���H���=���H��8���H��8��� t9��j  ��~YH��8����@4H��p���H�щ�H�5$=  �   �    �F����+�Mj  ��~ H��p���H��H�57=  �   �    �����"j  ��~4���������P���H��������H�5"=  �   �    ��������������������;������~���H��P���H��P���H��P���H��X�����i  ��~%H�=�i  �s���H��H�5�<  �   �    �u���H��i  H�����H�����H� H������>  H�����H��(���H��(���H��0���H��0����@9����tU�,i  ��~,H��0����P4H��0�����H��H�5j<  �   �    ����H��0���H��P���H��H���R����  H��0����@8������   H��0����@;������   ��h  ��~$H��0���H�@H��H�5)<  �   �    �s����|h  ��~9H��0���H�@H�PH��0���H�@H� H��H��H�5<  �   �    �/���H��0���H�@H�@H������H��0���H�@H�@    ��   H��0����@;����   H��0����@8��g  ��~(H��0���H�@H�@H��H�5�;  �   �    询����g  ��~$H��0���H�@H��H�5�;  �   �    耢��H��0���H������������������ t0H��0���H�@H�@��������H��H�5�;  �    �    �2���H�����H�����H�����H� H�����H�;g  H9���������H��P���H�����H�����H� H������   H�����H�����H�����H�� �����f  ��~0H�� ���H�PH�� ����@4H�щ�H�5:;  �   �    脡��H�� ����@4���@���H�� ���H������H�� ���H�@H��� ��H�� ���H�����H�����H�����H�����H� H�����H��P���H9�����4����f  ��~%H�=,f  �ݰ��H��H�5�:  �   �    �ߠ��������H�M�dH3%(   t�T����UH��H�� H�}�H�E�H�@H�PH�E�H�@H� H��H���~���E��E����tu���
���t�   ���t7����   �   �re  ����   H�5B:  �   �    �D����   �He  ����   H�5H:  �   �    �����   �e  ����   H�5^:  �   �    �����m��d  ��~eH�E�H�@H�@H��H�5d:  �   �    辟���>��d  ��~6�E�������H�E���H�5T:  �   �    艟�����
��������E���UH��H���   dH�%(   H�E�1�ƅ��� ƅ��� �Vd  ��~H�5:  �   �    �,���H��d  H�� ���H��H���"��������d  ��~�������H�5�9  �   �    ����ǅ���    ��  H�� ��������Hc�H��H�H� H��P���H��H��������������� tN��c  ���k  ���������~��H�Ƌ���������A�Љ�H��H�59  �   �    �Q����,  H�� ��������Hc�H��H�H� H�5:2  H��������uK�(c  ����  ��Z�������X����Ћ����A�ȉщ�H�5�3  �   �    �ٝ���  H�� ��������Hc�H��H�H� H��(���H��H���{������������ �:  ��`�����H��(���H�U�A�@   H�Ѻ	  H���4�����y=�ob  ��~�������H�5S3  �   �    �=���H��(���H���|���  H��p���H�E�H��H���>����b  ��~ H��p���H��H�5&3  �   �    ����H��p���H���'���������  �@   ��|��H��H���H��H��� ty�h   ��|��H��H��H���H�PH��H���H�@H��unH�5�7  �    �    �u���H��H���H�@H��tH��H���H�@H���!z��H��H���H���z��ƅ����H�5�7  �    �    �$���ƅ�������������m  H��H���H�H H��P����   H��H����{��H�� ��������Hc�H��H�H��H���H�@H�H�H��p���H���a}��H��H��H���H�PH��p���H���z��H��H��p���H��H���a�����H��H����P4�}`  ��~DH��H���H�HH��H����@*��H��H����@(��I�ȉщ�H�5�6  �   �    �%���H��H���H�@H��(���H�PH��H����@8 �`  ��~9H��H���H�@H�PH��H���H�@H� H��H��H�5�6  �   �    �����H��H���H�5�_  H������ƅ����   ��_  ��~ H��p���H��H�5�6  �   �    �s���H��(���H���Sy��ƅ��� �?�d_  ��~4��������z��H�������H�5d2  �   �    �"�����������������;�����.�������� �  H�� ����    H����z��H�
_  H��0�����   H��0���H��8���H��8���H��@���H��@����@8������   ��^  ��~$H��@���H�@H��H�5�5  �   �    �n����w^  ��~9H��@���H�@H�PH��@���H�@H� H��H��H�5�5  �   �    �*���H��@���H�@H�@H���x��H��@���H�@H�@    H��0���H� H��0���H�^  H9�0������������H�M�dH3%(   t�Ow����UH��{^  �ƿ    �x��H�H^  H���Xy���]�UH��H��0H�}؉u�dH�%(   H�E�1�H�E�    �E�����H�E�H���y��H�E��b]  ��~"�U�H�E؉�H��H�5�4  �   �    �,���H�U�H�E�H��H���w���E�}� u�E���H�U�H�E���H���Ww���E��3��\  ��~(�E���-x��H�E��H�5�4  �   �    ������}� ��   H�E�H����   H�E��@�ЋE�9���   ��\  ��~#H�E��@����H�5�4  �   �    �e���H�E��@��H�E؉�H����w���E�}� t3�L\  ��~(�E���}w��H�E��H�5V4  �   �    ����H�E�H���Cv���}� t&�\  ��~�E��H�5F4  �   �    �ؖ���E�H�M�dH3%(   t�Pu����UH��H��`�}�H�u�H�U�H�M�L�E�dH�%(   H�E�1�H�E�H���8w��H�E�H�E��  H�E��  H�E��  H�U�H�E�    H���u���EЃ}� uR�}� xH�E��@��9E�|o�E[  ��~(H�E��@�ЋẺщ�H�5�3  �   �    �	����E������3�	[  ��~(�EЉ��:v��H�EЉ�H�5�3  �   �    �͕���}� ��   H�E�H�@�U�Hc�H��H�H� H�E��E�    �   H�E�H�@�U�Hc�H��H�H�E�H�E��@������uWH�E��@��y&�}� uH�E��PH�E���<H�E��PH�E���,H�E��@��xH�E��PH�E����E�������E������E�H�E��@��9E��^����}� �<  ��Y  ��~#H�E��@����H�5�2  �   �    �����H�E��@��H�E���H���u���EЃ}� ��   �EЃ��t���tQ���t)�m��Y  ����   H�5�2  �   �    �b����i�iY  ��~aH�5�2  �   �    �?����I�FY  ��~AH�5�2  �   �    �����)�#Y  ��~!H�5�2  �   �    ������	���������X  ��~(�EЉ��'t��H�EЉ�H�5�2  �   �    躓���E�����H�E�H����r���E�H�M�dH3%(   t�r����UH��H��0H�}��H�U؉M�D�EԈE�dH�%(   H�E�1��E�    D�E��u�H�}��M�H�U�H�E�E��I��H���s���E�}� ��   �3X  ��~�E��H�5"2  �   �    �����}��u-�X  ��~H�52  �   �    �ݒ���E������   �}��u1��W  ����   �E��U��щ�H�52  �   �    蜒���u��W  ��~(�E����r��H�E��H�52  �   �    �g����E������9�E�9E�~1�_W  ��~&�U��M��E�A�ȉщ�H�52  �   �    �%����E�H�M�dH3%(   t�p����f.�     �AWAVI��AUATL�%.Q  UH�-.Q  SA��I��L)�H��H���oo��H��t 1��     L��L��D��A��H��H9�u�H��[]A\A]A^A_Ðf.�     ��  H��H���         ctrl_handler %d Ctrl-C event    Could not set control handler : %d      The posix signal handler is installed   EXIT server     Entering non_blocking_accept_main ask_to_kill asked select failed. Error = %d   select failed. Error = %d (EINTR)       No connections/data in the last %ld seconds. ask_to_kill cancelled listening state : %d evaluate_auto_kill after listening accept error List of SockInfo %p     help version debug port auto-kill log_output hvd::l:p:a Parse param : %d --auto_exit  4 ***debug_level %s --log_output %s --log_output %s2 7184 ***port %s stlink-server
       --help       | -h	display this help
    --version    | -v	display STLinkserver version
 --port       | -p	set tcp listening port
       --debug      | -d	set debug level <0-5> (incremental, 0: Error, 1:Info, 2:Warning, 3:STlink, 4:Debug, 5:Usb)
   --auto-exit  | -a	exit() when there is no more client
  --log_output | -l	redirect log output to file <name>
   failed to convert address to string (code=%d) Remote address: %s        Entering create_listening_sockets()     Creating the list of sockets to listen for ... interface, tcp port : %s , %s default port : %s  getaddrinfo failed. Error = %d  getaddrinfo returned res = NULL getaddrinfo successful. Enumerating the returned addresses ...  Processing Address %p returned by getaddrinfo(%d) : %s  socket failed. Error = %d       Ignoring this address and continuing with the next.     Created socket with handle = %d 127.0.0.1       Error setting socket opts: %s, TCP_NODELAY
     Error setting socket opts: %s, SO_RCVBUF
       Error setting socket opts: %s, SO_SNDBUF
       stlinkserver already running, exit bind failed. Error = %s 
 Socket bound successfully listen failed. Error = %d Non Blocking Setting   Can't put socket into non-blocking mode. Error = %d alloc_sock_info failed.     Added socket to list of listening sockets       Freed the memory allocated for res by getaddrinfo       Exiting create_listening_sockets()      Entering destroy_listening_sockets()    prepare to close socket with handle %d Closed socket with handle %d     Exiting destroy_listening_sockets()     Entering process_accept_event() on socket %d, sock_info %p      ERROR: accept failed. Error = %d        Added accepted socket %d to list of sockets     Previously recd data not yet fully sent.        recv got WSAEWOULDBLOCK. Will retry recv later ...      ERROR: recv failed. error = %d  recv returned 0. Remote side has closed gracefully. Good.       get_stlink_tcp_cmd_data: recv timeout. error = %d       get_stlink_tcp_cmd_data: recv failed. error = %d        get_stlink_tcp_cmd_data: recv returned 0 write cmd. Unexpected client socket closed     get_stlink_tcp_cmd_data: select timeout (no error)      get_stlink_tcp_cmd_data: select timeout. error = %d     get_stlink_tcp_cmd_data: select failed. error = %d No data pending to be sent.  send got WSAEWOULDBLOCK. Will retry send later ...      ERROR: send failed. error = %d  Sent %d bytes. Remaining = %d bytes. Error:  Info :  Warn :  Stlk :  Debug:  Usb  :  %s%d %d :  w       . - Server version %d %d %d 
   ERROR: Server version not set (too high) ERROR: Server version not set  stlink-server v%lu.%lu.%lu (2023-06-02-08:34) 
 7184 stlink-tcp initalization Cannot install signal handler create_listening_sockets    libusb_init(): Cannot initialize libusb non_blocking_accept_main destroy_listening_sockets libusb_mgt_exit_lib  Delete stlink next %p, list previous %p get_stlink_by_key 0x%x to find, usb device ptr %p, usb_key 0x%x usb not found : 0x%x    get_stlink_by_serial_name usb instance %p, key %x usb not found : 0x%lx Get_device_info (index: %d) return usb device ptr %p    Get_device_info usb found 0x%x, (PID 0x%x, serial %s)   Get_device_info, Usb device NOT found (device index: %d)        stlink_open_device 0x%x (usb) with 0x%x (psock_info)    stlink_open_device: libusb_open of libusb dev %p return %d and libusb handle %p Opened device usb_key 0x%x Opened device ERROR : %d     stlink_open_device: libusb_open device failure 0x%x     stlink_open_device: Error in association creation       stlink_open_device: libusb handle %p already opened     stlink_open_device: Error unkown device 0x%x assoc null stlink_close: close_connection(assoc_id 0x%x)   STlink device has been disconnected, need to close (assoc 0x%x) unknown assoc : 0x%x    alloc_init_sock_info: malloc returned NULL.     alloc_init_sock_info : Allocated %p Freed sock_info at %p       Delete SockInfo next %p, list previous %p       Refresh: Opened assoc cookie_id 0x%x (for usb_key 0x%x) becomes invalid add to list assoc of usb device ptr %p, sock_info ptr %p        Malloc error: %p, sock_info %p not added to assoc list New stlink sock_info key 0x%x    New stlink assoc key 0x%x (ptr %p) Reuse a stlink assoc key 0x%x not ask to exit() because %d   close_connection : assoc cookie_id 0x%x close_connection : usb to find  0x%x, connection_count %d       close_connection : assoc key 0x%x found as the last user of stlink (assoc ptr %p)       close_connection : libusb_close %s last tcp client : %d close_connection : No Stlink USB close, device already disconnected previously  TCPCMD REFRESH_DEVICE_LIST : unexpected TCP cmd size %d instead of %d   TCPCMD REFRESH_DEVICE_LIST : return %d  TCPCMD GET_NB_DEV : unexpected TCP cmd size %d instead of %d    TCPCMD GET_NB_DEV : %d device(s)        TCPCMD GET_NB_OF_DEV_CLIENTS : unexpected TCP cmd size %d instead of %d TCPCMD GET_NB_OF_DEV_CLIENTS : %d client(s) for stlink_usb_id 0x%x      TCPCMD GET_DEV_INFO : for device index %d (info size %d)        TCPCMD GET_DEV_INFO : unexpected TCP cmd size %d instead of %d  TCPCMD OPEN_DEV : unexpected TCP cmd size %d instead of %d      TCPCMD OPEN_DEV for stlink_usb_id : 0x%x, access: %d (sock info 0x%x)   TCPCMD OPEN_DEV FAIL, internal assoc not key created    OPEN success, created cookie_id: 0x%x   TCPCMD CLOSE_DEV : unexpected TCP cmd size %d instead of %d     TCPCMD CLOSE_DEV for cookie_id: 0x%x    TCPCMD SEND_USB_CMD : unexpected TCP cmd size %d instead of %d minimum  TCPCMD SEND_USB_CMD : cookie_id 0x%x, CMD : 0x %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x %02x, %02x, %02x, %02x    REQUEST_WRITE : 0x%x bytes received Write 0x%x bytes REQUEST_READ TRACE Cmd data size %d larger than max supported size %d      TCPCMD SEND_USB_CMD : unexpected TCP cmd+data size %d instead of %d     TCPCMD SEND_USB_CMD : unexpected TCP cmd size %d instead of %d  TCPCMD SEND_USB_CMD : stlink_send_command error %d      ANS (0x%x bytes): 0x %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x ... ANS (0x%x bytes): 0x %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x     ANS (0x%x bytes): 0x %02x, %02x TCPCMD GET_SERVER_API_VERSION : unexpected TCP cmd size %d instead of %d        TCPCMD GET_SERVER_API_VERSION cmd, client API v=%x server API v=%x get-nb-stlink        get-nb-stlink : command received from (%s) 1 %d
        get-nb-stlink: (%s) : returned value '%s' get-stlink-descriptor get-stlink-descriptor : command received from (%s) 1 %x %x %x %s
       get-stlink-descriptor : (%s): returned value : %s serial code %s usb not found %d open-device %x        open-device : commmand received from (%s) : 0x%x, 0x%x  process open-device (%s): cookie_id = 0x%x      process open-device (%s): error open-device : (%s): returned value "%s" close-device %d close-device : commmand received from (%s) : cookie_id = 0x%x   close-device (%s): returned value %s stlink-tcp-version stlink_tcp_version assoc %p     stlink-tcp-version : command received from (%s) 1 %d %s %d %d %d %x %x
 stlink-tcp-version : (%s) returned value '%s' usb-refresh       usb-refresh : command received from (%s)        usb-refresh : (%s) returned value '%s' stlink-blink-led stlink-blink-led : command received from (%s)   Index %d is stlink_usb key 0x%x stlink-blink-led : (%s) returned value '%s' register-client     register-client : (%s) returned value '%s'      TCPCMD : unknown command received %s    process_stlink_tcp_cmd : returned value %s      send_cmd: Internal error NULL stlk_dev* send_cmd: Internal error NULL stlk_dev_handle* STlink cmd send on USB failed    STlink cmd data send on USB failed      STlink cmd data read on USB failed      STlink cmd unexpected request type %d   read_trace_data: Internal error NULL stlk_dev*  read_trace_data: Internal error NULL stlk_dev_handle* STlink read trace data failed     get_version: Internal error NULL stlk_dev*      Nucleo STM8 detected, not supported by stlinkserver     get_current_mode: Internal error NULL stlk_dev* STLink GET_CURRENT_MODE cmd sent (status %d): mode %d   jtag_exit: Internal error NULL stlk_dev*        STLink JTAG_EXIT cmd sent (status %d)   exit_jtag_mode: Internal error NULL stlk_dev* STLink current mode: 0x%02X       dfu_exit: Internal error NULL stlk_dev* STLink DFU_EXIT cmd sent (status %d)    exit_dfu_mode: Internal error NULL stlk_dev*    blink_led: Internal error NULL stlk_dev*        STLink BLINK_LED cmd sent (status %d)   no execution because the jtag version %d is too low     libusb_release_interface debug libusb_close %p  stlink_mgt_open_usb_dbg_if: Internal error NULL stlk_dev*       stlink_mgt_open_usb_dbg_if: Internal error NULL stlk_dev_handle*        stlink_mgt_open_usb_dbg_if : for libusb dev_handle = %p libusb_mgt_claim_interface failed       STLINKV2 v%dJ%dS%d, PID 0x%04X  STLINKV2-1 v%dJ%dM%d, PID 0x%04X        STLINKV3 v%dJ%dM%d, PID 0x%04X  STLINKV3 v%dJ%dM%dB%dS%d, PID 0x%04X    STLINKPWR v%dJ%dM%dB%dP%d, PID 0x%04X   new STLINK v%dJ%dM%dB%dS%dP%d, PID 0x%04X       Usb open debug interface Error: libusb_close %s         H7J7K7N7O7R7S7T7V7W7    %02hX   Error libusb_get_device_descriptor (%s, %d) plug event dev %p unplug event dev %p Unhandled event %d    libusb_init, libusb version : %d.%d.%d.%d : %s Error libusb_get_version Refresh list, usb instance %p, usb_key 0x%x     Refresh: libusb_close before refresh %s libusb_close libusb_handle %p   Refresh: libusb_get_device_list found %d device Refresh: Error libusb_get_device_descriptor (%s, %d) for device %d      device %d (VID 0x%04X, PID 0x%04X) is not an STLink     Error getting SerNum of device %d
      Refresh: libusb_open success %s Refresh: Malloc error new stlink NOT added      Refresh: Add device %s to USB list: VID 0x%04X, PID 0x%04X      new libusb_device = %p, libusb_handle = %p      Refresh: Malloc error libusb_close STLink %s    Refresh: keep stlink device unchanged in device list %s Found VID 0x%04X, PID 0x%04X, libusb_device = %p, libusb_handle = %p    Updated libusb_device = %p, libusb_handle = %p  Refresh : unusable stlink device, key 0x%x for serial %s        Refresh : unusable stlink device %s Error libusb_open (%s, %d) count stlink_usb_list :%ld       move usb device to usb_delete_list %p, usb_key 0x%x     Refresh: libusb_close usb Device %s     close usb libusb_device = %p, libusb_handle = %p        usb already opened. libusb_handle %p    Refresh: keep libub_open after refresh %s       Refresh: Unable to claim interface again for libusb_handle %p, error %d Refresh: remove from USB list usb_key 0x%x, %s Refresh: List USB :%ld   libusb_open Error: Memory allocation failure    libusb_open Error: The user has insufficient permissions        libusb_open Error: The device has been disconnected     libusb_open OK, libusb dev_handle %p libusb_open Error (%s, %d) libusb_get_device_list entry    libusb_get_device_list found %d device  Error libusb_get_device_descriptor (%s, %d) for device %d       Init refresh : Malloc error new stlink NOT added        Add to stlink USB list: VID 0x%04X, PID 0x%04X, serial %s       Init refresh : new libusb_device = %p, libusb_handle = %p       Init refresh : Malloc error libusb_close STLink %s libusb_close USB device %s   libusb_close USB libusb_device %p, libusb_handle %p     libusb_get_configuration for dev_handle = %p, configuration = %d        Error libusb_get_config_descriptor (%s, %d) libusb_set_configuration : %d       Error libusb_set_configuration (%s, %d) libusb_mgt_set_configuration : return %d        libusb_mgt_claim_interface : interface %d > bNumInterfaces %d   Error libusb_get_config_descriptor (%s, %d) in claim interface libusb_claim_interface %d        libusb_claim_interface error LIBUSB_ERROR_NOT_FOUND     libusb_claim_interface error LIBUSB_ERROR_BUSY  libusb_claim_interface error LIBUSB_NO_DEVICE libusb_claim_interface error      Error libusb_claim_interface (%s, %d)   libusb_bulk_transfer: Error %d  libusb_bulk_transfer: Error USB device disconnected     libusb_bulk_transfer: Error timeout, transferred %d/%d bytes    libusb_bulk_transfer: Error (%s, %d)    libusb_bulk_transfer: No error (%d) but transferred %d/%d bytes ;  b   �=��h  �A���   B��8  
C���  dC���  5D���  MD��  �D��(  �D��D  &J��h  _M���  �M���  �M���  �M���  wN��  �T��(  �U��H  �W��h  <Y���  �\���  \^���  �^���  �_��  �a��(  b��H  Gb��h  �d���  #e���  �f���  �f���  ?g��  �g��(  �g��H  �h��h  zi���  �i���  �i���  'k���  \k��  �m��(  �m��H  �m��h  xn���  �o���  p���  Zp���  lp��	  )q��(	  mq��H	  �q��h	  r���	  Vr���	  �r���	  Ts���	  �s��
  �s��(
  nt��H
  �u��h
  Sv���
  @x���
  �x���
  �x���
  cy��  �y��(  �y��H  �z��h  ͜���  ����  �����  �����  ����  ���0  ���P  ����p  ݥ���  �����  �����  ����  ����  ����0  ���P  )���p  p����  �����  ����  ����  ����  c���0  &���P  ���p  .����  |����  3����  [����  2���  c���0  ����P  `����             zR x�      �>��+                  zR x�  $      @:��@   FJw� ?;*3$"       D   X>��              \   Z?��Z    A�CU     |   �?���    A�C�     �   E@��    A�CS      �   =@��_    A�CZ     �   |@��>    A�C       �   �@��<   A�C7          �E��9   A�C4    <  �H��E    A�C@     \  �H��    A�CB      |  �H��"    A�C]      �  �H���    A�C�     �  gI��6   A�C1    �  }O��   A�C    �  |P��   A�C      oR��]   A�CX    <  �S���   A�C�    \  W���   A�C�    |  �X���    A�C�     �  �X��   A�C    �  �Y���   A�C�    �  �[��+    A�Cf      �  �[��<    A�Cw        �[��_   A�CZ    <  ^��}    A�Cx     \  s^��h   A�Cc    |  �_��G    A�CB     �  �_��m    A�Ch     �  /`��N    A�CI     �  ]`��]    A�CX     �  �`���    A�C�       0a���    A�C�     <  �a��\    A�CW     \  &b��    A�CM      |  b��?   A�C:    �  7c��5    A�Cp      �  Lc��~   A�Cy    �  �e��    A�CG      �  �e��    A�CH        �e���    A�C�     <  �e��^   A�CY    \  &g��=    A�Cx      |  Cg��G    A�CB     �  jg��    A�CM      �  \g���    A�C�     �  �g��D    A�C      �  h��]    A�CX       Zh��E    A�C@     <  h��G    A�CB     \  �h��h    A�Cc     |  �h���    A�C�     �  di��9    A�Ct      �  }i��    A�CP      �  ri���    A�C�     �  j���   A�C�      �k��Z    A�CU     <  �k���   A�C�    \  �m��U    A�CP     |  �m��f    A�Ca     �  n��h    A�Cc     �  Sn��O    A�CJ     �  �n��    A�CZ      �  �n���    A�C�  $     )o��4"   A�CN����!"   D  5���O    A�CJ     d  d����   A�C�    �  $����    A�C�     �  ē��C    A�C~      �  ���   A�C    �  ����    A�C�     	  �����    A�C�     $	  "���C   A�C>    D	  E����    A�C�     d	  ҙ��   A�C    �	  ˚��C   A�C>    �	  ����    A�C�     �	  w���   A�C    �	  i���C    A�C~      
  ����E    A�C@     $
  ����G    A�CB     D
  ؠ��K    A�CF     d
  ���a    A�C\     �
  D����    A�C�     �
  ����    A�C�     �
  �����    A�C�     �
  +����    A�C�       Σ���    A�C�     $  o���G   A�CB    D  ����N   A�CI    d  ı���   A�C�    �  [���(    A�Cc      �  c����   A�C�    �  ���1   A�C,    �  +����   A�C} D     ����e    B�B�E �B(�H0�H8�M@r8A0A(B BBB    L  ����                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  �      0�              � !            5�              � !            =�                     d       C�                     p       H�                     a       R�                     l                                       M�      U�      ]�      e�      m�      u�                                         \                          �             ��             P�                           X�                    ���o    �             X
             �      
       /                                          ��             H                           h             �             �      	                            ���o          ���o    (      ���o           ���o    �      ���o                                                                                           p�                      �      �                  &      6      F      V      f      v      �      �      �      �      �      �      �      �                  &      6      F      V      f      v      �      �      �      �      �      �      �      �                  &      6      F      V      f      v      �      �      �      �      �      �      �      �                  &      6      F      V      f      v      �      �      �      �      �      �      �      �                                                                                     !      !      !                   0 !     0 !     @ !     @ !     GCC: (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0 ,             *      +                      ,    �       U      �                      ,    o       F%      9                      ,    P"       (      �                      ,    �2       |9      �                      ,    �8       g=      D                      ,    �?       �A      �	                      ,    �O       3K      �                      ,    �Y       �L      �                      ,    1i       �T      j#                      ,    �{       �w      �                      ,    ��       ��      D                       �       �    �  *      +          4   �8   �   .  �  �   0  b   %?   N  �  'F   int G  )M   �   �  �M       ��   R  ��   F  �x   E  ��   �   7  �   �  ��\  	n   �x    	   ��   	  ��   	  ��   	�  ��    	�  ��   (
�   �   0
�   �   8
_  �   @
  �   H
F  �   P
  �   X
  �  `
   
�  h
  x   p
]  x   t
�  �   x
k  F   �
�  T   �
"   �  �
O  �  �
�  %�   �
X  -�   �
_  .�   �
f  /�   �
m  0�   �
t  2-   �
�  3x   �
{  5�  � �  �|  ��  	`  ��   	�  ��  	�  �x    c  �   �   �  8     \  �   �  8    �  u  ?�  �  @�  u   A�  �   �  �  ��  e  ��  �  ��  �  x   �  1   &  �  1  �V  	�  V    8   f  8    �  A  �   �   R  4�  	6  6x    	�  7x      �  @  	�    	x   �  	�    C   	�  
8�  	\  
:�    	   
;�    
?+  	�  
Ax    	~  
Bx   	=  
C�   
GX  	\  
I�    	   
J�   	=  
K�    
O�  	\  
Q�    	   
R�   	�  
Sx   	�  
T�   	V  
U�    
a�  	�   
c�    	w  
d�    
^�  <  
e�     
g     
Y
  	;   
[�    	1  
]f   	�  
h�   
l+  	�  
n�    	�  
ox    
tX  	X  
v�    	l  
wx   	�   
xM    p
3�  �  
5�  V
  
<�  �  
D�  _rt 
L+  %  
VX    
i�  �  
p
  U  
y+   x   �  8    �
$  	  
&x    	N   
(x   	�  
*x   	Q  
0x   	�  
{X     
|�  �   H$  *  5  x    T  �    <  !o   i  x   i  �      T  ?  ��  	�  #5   	I  +f  	l   .x   �	�  1�  � �  �  �  8   @ �  '  �  (  �  �  "�  �   �  $�   �  2x   �  7x   �  ;x   d   [   �  m   I     �o  �  �o  .  �  :  ُ   $    8    /  �  8    :  �  8    r  Ӹ  	,   �E    �  �  �  �  �  (    �  	�  ��    	�   ��   	  ��      ��  W   x   /^  �  ~�  c   )  o  �   �   q  �   c  Fx   �  d�  �      �       ��  act fu  ��~rc gx   ��~  �  E*      Z       �!sig Ex   �l"4  Ei  �`"9  E�   �X  ~   �  �  �  �  U      �        4   �8   �   .  �  �   0  b   %?   N  �  'F   int G  )M   �   �       ��   R  ��   �  ��   �  ��   �   7  �   �  ��V  	n   �x    	   ��   	  ��   	  ��   	�  ��    	�  ��   (
�   �   0
�   �   8
_  �   @
  �   H
F  �   P
  �   X
  �  `
   
�  h
  x   p
]  x   t
�  �   x
k  F   �
�  T   �
"   �  �
O  �  �
�  %�   �
X  -�   �
_  .�   �
f  /�   �
m  0�   �
t  2-   �
�  3x   �
{  5�  � �  �|  ��  	`  ��   	�  ��  	�  �x    ]  �   �   �  8     V  �   �  8    �  u  ?�  �  @�  u   A�  �   �  �  ��  e  ��  �  ��  �  x   �  +      �  +  �  x   �  +    v  	�
  
�    	i  �    �  	1�   �	;�  	�
  	@�    v  �  8    <  	F�  �   �   R  
4�  	6  
6x    	�  
7x    �  �  5  F   �  �  	�  ��   	i  �$   �  �   4  8    �  4   	  ?  ?  I  �  T  T  ^  �  i  i  s  y	  ~  ~  �  �
  ��  	�  ��   	`	  �+  	�  �  	  �   �  �  �  S  �,  	{
  ��   		  �+  
�   �  
q  �  
�  �   �  �  1  Z  <  <  F  C  Q  Q  [  �  f  f  p  �  {  {  �  �	  �  �  �  f  �  �  �    �  D  �  Y  �  n  �  �  �  �  �  ,  �  A    V    k    �  (  �  3  �  >  �  Y  8   @ I  '  Y  (  Y  
  -�   K  .�   ?   �  8    �  "�  �   �  $�  �  $�   �  2x   �  7x   �  ;x   d   [   �  m   I     h  �  �  +  	$  !    �  w�  �`  �  �`  .  �p  :  ـ   �  p  8    �  �  8    �  �  8    r  ө  	,   �6    �  �  �  �  �  �  Lx   &	  �  	a  �   	  �   �  �  
  �.@  buf /@   +  0x    ��	  1M   �;	  2Q  � �   Q  8   � (  Q  �  h�9�  	�   :�   	
  <�  	P  =Q  	�  ?�  0	  @x   $�1  Ax   (�9  BQ  ,�key CM   0��
  D�  4� �   �  8   1   �	  	�  ��    	�   ��   	  ��      ��  W   x   /p	  �  ~�  c   )  o  �   �   q  �   c  Fx   C  (*�	  	n  +�   	�  ,�	  	�
  .C
  	  /Q   key 0M   $ ]  �
  @+C
  	n  ,�   	�  -�  	<  .�   		  /�
   key 0M   4	�  1Q  8	-  2Q  9	�
  3Q  :	\
  4Q  ; �	  �   Y
  8    d  �I
  �  �x   P  ��   f  �I
  �  �x   R  ��   �  x   A  �k  
1  ��   
@
  ��  
{  ��  
[  ��  
�  ��  
0
  ��  
i	  ��  
�
  �  
�  �  

�  �  
  
�  
r  �  
�  �  
�  �   �	     �|    !�  M   R�     5    �  {  �  q   �	  ��  
~  �M    
�  �M   
�  ��    �	  ��    "  #     �  @��  
�  ��   
o   ��  
J  �?   	
  �?   

m  �M   
�  ��  
~  �x   
�  �x   
�  ��   
	  ��   (

  ��  0
�  �x   8
k
  ��  < p  ?   �  �  $8    �  h:�  dev ;�   	�  <�  	`  =  	�
  >�  	�  ?�  	,  @�  	  A�  	�  B�  ;vid C�  \pid D�  ^	�	  E�  `	%  F�  a �  k  |  �  �  8      6x   %	  8	� !     &P
  :X  	� !     &�	  <�  	 !     '�  a
       <      ��  (�
  c�   ��~(7  e�  ��~(  gQ  ��~(�
  hx   ��~(S	  iQ  ��}(	  jx   ��~(�  kx   ��~)err lx   ��~(�	  mQ  ��}*�  sn       +m       �      (Q  }�  ��~,|       (       �  (
  x   ��~(f
  x   ��~ ,�       x       :  (%  ��	  ��~+�              (�  ��  ��~  +#      �      (%  ��	  ��~,#               (�  ֤  ��~ +i$      �       -,  �  ��~    �  {	  .�
  Q�      >       �/
  >�	  m      _       �U  0nth >M   �L(Q  @�  �P(�  A8   �X+�      $       (%  D�	  �h+�             (�  D�  �`   1u  �Q  U             �2&	  ��  �h  �   J  �  �  �  F%      9      �  4   �8   �   .  �  �   0  b   %?   N  �  'F   int G  )M   �       ��   R  ��   �   7  �   �  ��;  	n   �x    	   ��   	  ��   	  ��   	�  ��    	�  ��   (
�   �   0
�   �   8
_  �   @
  �   H
F  �   P
  �   X
  s  `
   
y  h
  x   p
]  x   t
�  �   x
k  F   �
�  T   �
"     �
O  �  �
�  %�   �
X  -�   �
_  .�   �
f  /�   �
m  0�   �
t  2-   �
�  3x   �
{  5�  � �  �|  �s  	`  �s   	�  �y  	�  �x    B  �   �   �  8     ;  �   �  8    �  u  ?�  �  @�  u   A�  �   �  �  �y  e  �y  �  �y  �  x   �       �    �  x   �    �   �   R  4i  	6  6x    	�  7x    D  i  5  F   �  	��  	�  	�t   	i  	��     �   �  8      �   	  �  �  �  �  �  �  �  �  �  �  �  y	        �
  
�U  	�  
�t   	`	  
�  	�  
�  	  
�       Z  S  
��  	{
  
�t   		  
��  
�  
 �  
q  
  
�  
�   e  e  �  Z  �  �  �  C  �  �  �  �  �  �  �  �        
  �	        f  *  *  4  �  ?  �  J  �  U  �  `    k  U  v  �  �  �  �  �  �  �  �    �    �  /  �  �  �  8   @ �  '  �  (  �  
  -�   K  .�   ?   !  8    �  "-  �   �  $-  �  $�   �  2x   �  7x   �  ;x   d   [   �  m   I     h  
�  �  
�  	$  
!�    �  
wv  
��  �  
��  .  
��  :  
�   k  �  8    v    8    �    8    r  
�.  	,   
ڻ      �  
�.  �  
�.  (    ��  	�  ��    	�   ��   	  ��      �P  W   x   /�  �  ~�  c   )  o  �   �   q  �   c  Fx   �   2  	Q  4�   	�  7x   	�  8!  val 9x    �  x   �  .x   	� !     �  /x   	� !     �  1I    l  8    \  s  4l  	`�      �  >x   F%      9      ��  >x   �\�  >-  �Pc @x   �d    �  Dx   �`   F   �  �    �  (      �      �  .  �  �   �   0  b   %-   N  �  '4   int G  );   �       �   R  �   �  �   �  �   �   7  �   G  �;   4   �B   I  �   	�  "�   �   	�  $�   
�  $�   
�  2m   
�  7m   
�  ;m   �   2  &	  b  a  g     g   =  =  �  ���  n   �m       ��     ��     ��   �  ��    �  ��   (�   �   0�   �   8_  �   @  �   HF  �   P  �   X  %  `   
+  h  m   p]  m   t�  �   xk  4   ��  I   �"   1  �O  A  ��  %�   �X  -�   �_  .�   �f  /�   �m  0�   �t  2�   ��  3m   �{  5G  � �  �|  �%  `  �%   �  �+  �  �m    �  m  �   A  B     �  �   W  B    �  	u  ?W  	�  @W  	u   AW  
�  �+  
e  �+  
�  �+  
�  	m   8  �   �  
�  	�  
�  	m   
�  	�    
  �
  

�    i  
�    �  1   �;"  �
  @"      2  B    <  F  �   �   R  4p  6  6m    �  7m    K  p  �  ;   �    �  G  �  �  �  Z  
M         5  4   �  ��  �  ��   i  ��   �  �     B    s  ��=  �  ��   f  �=    �B   x �   M  B   u �  M   	  X  X  b  �  m  m  w  �  �  �  �  y	  �  �  �  �
  ��  �  ��   `	  �  �  ��    ��   �  �  �  S  �E  {
  ��   	  ��  �   �  q  
	  �  �   �  �  J  Z  U  U  _  C  j  j  t  �      �  �  �  �  �  �	  �  �  �  f  �  �  �  �  �  ]  �  r  �  �  �  �  �  �  
  E    Z     o  +  �  6  �  A  �  L  �  W  8  r  B   @ b  	'  r  	(  r  

  -�   
K  .�   -   �  B    d   P   �  b   I  t   h  �  �  �  $  !�    ;   )�      w  �  �  �  �  �  �  �  C    !:  )�  ..  /�  2�  32  \�  ^P  b"  g$  l�  ��  ��  ��  ��    �  w�  ��  �  ��  .  ��  :  ��   �  �  B    �  �  B    �  
	  B    r  �#	  ,   ڰ    
	  
�  �#	  
�  �#	    05�	  >  7m    �  8m   �  9m   �  :m   '  ;�   X  <M  {  =�    ^  >�	  ( >	  �  Lm   �  aM  1  c  
  �.
  buf /
   +  0m    ��	  1;   �;	  2-
  � �   -
   B   � (  �  h�9�
  �   :=   
  <�	  P  =-
  �  ?�	  0	  @m   $�1  Am   (�9  B-
  ,�!key C;   0��
  D�
  4� �   �
  B   1   ��
  �  ��    �   ��     ��    
  ��
  W   m   /G  "�  ~"�  c   )  o  �   �   q  �   
c  Fm   #  (m   	� !     
�	  4=  $  #-
  �7      �      ��  %B  #�  �X&S	  %-
  �g&8  &m   �h'err 'm   �l 4
  $�  �;   \4      �      ��  %B  ��  ��~%`  �;   ��~%�  ��   ��~&�  �;   ��~&�  �m   ��~&S	  �-
  ��~&7  �2  ��~&m  ��  ��~&�
  �m   ��~'err �m   ��~&�  �m   ��~(�4      (       &
  �m   ��~&f
  �m   ��~  $�  �-
  �2      ]      �;  %B  ��  �X&S	  �-
  �g&  �m   �h'err �m   �l $�  K�  �0            ��  %B  K�  ��~&l  M�	  ��~&�  Nm   ��~&�  O�	  ��~&  P�  ��~&�  QB   ��~'err Rm   ��~ )  1�/            �M  &Q  6g  �P'tmp 6g  �X(0      �       &%  8�  �h(0             &�  8M  �`   b  *S  g-
  �)      6      �d  +�  i>	  ��,res j�	  ��+v  k�	  ��+�  l�	  ��~+  m�  ��,i nm   ��~+�  oB   ��,ret p-
  ��~,err qm   ��~-n   Y/      (=+             +f  ��  �P+  �4   ��~+�  �m   ��~+�  �m   ��~,a �m   ��~  .�  >�(      �       ��  /�  >�	  ��/�  >B   ��+
  W�  ��,err Xm   �� �   �  B   - .�  6�(      "       ��  /  6�   �h 0v  +�(             �1*  S(      E       �/N  Sg  �h/l  Sg  �`  '   o  �  �  �  |9      �      T  4   �8   �   .  �  �   0  N  int �       �i   R  �i   �  �i   �  �i   �   7  �   �  ��0  	n   �b    	   ��   	  ��   	  ��   	�  ��    	�  ��   (
�   �   0
�   �   8
_  �   @
  �   H
F  �   P
  �   X
  �  `
   
�  h
  b   p
]  b   t
�  p   x
k  F   �
�  T   �
"   �  �
O  �  �
�  %{   �
X  -�   �
_  .�   �
f  /�   �
m  0�   �
t  2-   �
�  3b   �
{  5�  � �  �   d  (F    O  _  _  8     �   �  	�   M    	�   M   	0   �   	x   �    �  �|  ��  	`  ��   	�  ��  	�  �b    �  �   �   �  8     �  �     8    �  u  ?  �  @  u   A  �   /  k  .;  �  ��  e  ��  �  ��  �  	b   5  |   q  �  	|  �  	b   �  	|  �     
�  	�
  

�    	i  
�    �   R  4�  	6  6b    	�  7b    �  �  W   b   /M  �  ~�  c   )  o  �   �   q  �   c  Fb   M  8	  !       :~  	� !     0  �  =�  	� !     5  �  8    �  �  @�  	@�      �  Ib   	� !     B  �b   +=      <       �  f ��   �Xs  �~  �h 
  � =      +       ��  s;      �      ��  i  s  ��~�  t/  ��~ap w:  ��~ �;      �       t �b   ��~  \  Z	:            ��  i  Z  ��~�  [/  ��~ap ^:  ��~ !�  K�  |9      �       ��  M�  �P  N�  �Hret Ob   �D  �   )
  �  (  �  g=      D        .  �  �   �   0  b   %-   N  �  '4   int G  );   �       �   R  �   �   7  �   �   �   4   �B   �  ��F  	n   �m    	   ��   	  ��   	  ��   	�  ��    	�  ��   (
�   �   0
�   �   8
_  �   @
  �   H
F  �   P
  �   X
  ~  `
   
�  h
  m   p
]  m   t
�  �   x
k  4   �
�  I   �
"   �  �
O  �  �
�  %�   �
X  -�   �
_  .�   �
f  /�   �
m  0�   �
t  2�   �
�  3m   �
{  5�  � �  �|  �~  	`  �~   	�  ��  	�  �m    M  �   �   �  B     F  �   �  B    �  u  ?�  �  @�  u   A�  �  ��  e  ��  �  ��  �  m   �        �    �   �   �  ":  �   �  $�   �  2m   �  7m   �  ;m   R  	4�  	6  	6m    	�  	7m    l  �  �   
H�  �  �  m    �   �  B   @ �  '  
�  (  
�  d   P   �  b   I  t   �0  �  �0  .  �@  :  �P   �  @  B    �  P  B    �  `  B    r  �y  	,   �    `  �  �y  �  �y  (    ��  	�  ��    	�   ��   	  ��      ��  W   m   /  �  ~�  c   )  o  �   �   q  �   c  Fm   �   :  B    d  �*  �  �m   P  �   f  �*  �  �m   R  �   �  4	� !     �  }m   C@      h      ��  �  }m   �\�  }:  �Pret m   �l /  o�?      }       �!    qB   �PO  qB   �X�  qB   �` �  6g=      _      ��    6�  ��O  6�  ���  6�  ��G  8�  �_�  <�   ��=  =�   ��  >�   ��  ?�   ���  @B   �@�  @B   �P  @B   �H B    �   B     �   �  �  �  �  �A      �	      A  4   �8   �   int �   �   �   .  �  0  b   %[   N  �  'b   G  )F       �M   R  �M   �   7  �   �   �   �   	8    
�  ��Y  n   �?       ��     ��     ��   �  ��    �  ��   (�   �   0�   �   8_  �   @  �   HF  �   P  �   X  �  `   
�  h  ?   p]  ?   t�  �   xk  b   ��  i   �"   �  �O  �  ��  %�   �X  -�   �_  .�   �f  /�   �m  0�   �t  2-   ��  3?   �{  5�  � �  �
|  ��  `  ��   �  ��  �  �?    `  �   �   �  	8     Y  �   �  	8    �  u  ?�  �  @�  u   A�  �   �  �  ��  e  ��  �  ��  �  ?   �  .   #  �  .  
R  4c  6  6?    �  7?    >  c  �  ~  	8   @ n  '  	~  (  	~  �  
"�  �   �  $�   �  2?   �  7?   �  ;?   d   p   �  �   I  �   �$  �  �$  .  �4  :  �D   �  4  	8    �  D  	8    �  T  	8    
r  �m  ,   ��    T  �  �m  �  �m  �  L?   
  ��  �  ��    �   ��     ��      ��  
&	  �  a  �     �   �  �  
  �.@  buf /@   +  0?    ��	  1F   �;	  2Q  � �   Q  8   � (  �  h�9�  �   :�   
  <�  P  =Q  �  ?�  0	  @?   $�1  A?   (�9  BQ  ,�key CF   0��
  D�  4� �   �  	8   1 
V  e  �  hF      kF    
�  )rU  �  uF    �  {�   �  ~b   $�  �b   &w  �[   ( 
C  (*�  n  +�   �  ,�  �
  .    /Q   key 0F   $ X  
�
  @+  n  ,�   �  -S
  <  .�   	  /u   key 0F   4�  1Q  8-  2Q  9�
  3Q  :\
  4Q  ; �  �   3  	8    d  �#  �  �?   P  �M   f  �#  �  �?   R  �M   A  �9  1  ��   @
  ��  {  ��  [  ��  �  ��  0
  ��  i	  ��  �
  �  �  �  
�  �    
�  r  �  �  �  �  �   �	    �J    �  F   R�     5    �  {  �  q   �	  ��  ~  �F    �  �F   �  �O   �	  ��  �  �  �   �  �  @��	  �  ��	   o   ��  J  �[   	  �[   
m  �F   �  �O  ~  �?   �  �?   �  ��   	  ��   (
  ��	  0�  �?   8k
  ��	  < >  [   �  �	   8    
�  h:S
  dev ;Y
   �  <_
  `  =�  �
  >�  �  ?�  ,  @�    Ae
  �  Be
  ;vid C�  \pid D�  ^�	  E�  `%  F�  a �	  9  J  �  u
  	8    !W   ?   /�
  "�  ~"�  c   )  o  �   �   q  �   c  F?   #�  2�  	@ !     �  4�  $P  :8   �J      =       �8  %  :�  �X&Q  <�  �`&�  =8   �h '�  8   �I      ^      ��  %�  F   �L%)   �  �@(cmd �	  ��%
  �	  ��%�  8   ��&J  	�  �`&�  S
  �h)ret F   �\ �  U  *W  �8   I      �       �   +�  �F   �\,J  ��  �h -&  �8   I             �.  ��H             �*d  ��  |F      ~      ��  +  �F   �L+B  ��  �@,  �  �h,J  ��  �`/0   0ret �?   �\  *�  �F   GF      5       �  +  �F   �l+�  �  �`   *�  �8   E      ?      �T  +  �F   �\+�  �  �P,  �  �h -�  �F   �D             �1g    �D      \       ��  +a  F   �L,Q  ��  �X,�  �F   �T2�D      "       ,  �  �h2�D             ,�  ��  �`   �  *<  k  �C      �       ��  +<  k�   �H,Q  m�  �P,[  o8   �X2�C      V       ,  t  �h2�C             ,�  t�  �`   **  [  
C      �       �  +[  [F   �L,Q  ]�  �X2"C      Y       ,  `  �h2"C             ,�  `�  �`   3�  P�B      ]       �9  +  P  �h *g  DQ  _B      N       �u  +  D�   �X0k F8   �h 15  6�  �A      m       ��  4key 6�   �X4len 6-   �P,K  8�  �h0i 8�  �l 5�  d�A      G       �+Q  d�  �h  �	   �  �  �  �  3K      �        .  �  �   �   0  b   %-   N  �  '4   int G  );   �       �   R  �   �   7  �   4   �B   �  "�   �   �  $�   	�  $�   	�  2m   	�  7m   	�  ;m   
&	  *  a  *     *     
�  ���  n   �m       ��     ��     ��   �  ��    �  ��   (�   �   0�   �   8_  �   @  �   HF  �   P  �   X  �  `   
�  h  m   p]  m   t�  �   xk  4   ��  I   �"   �  �O    ��  %�   �X  -�   �_  .�   �f  /�   �m  0�   �t  2�   ��  3m   �{  5
  � �  �
|  ��  `  ��   �  ��  �  �m    �  0  �     B     �  �     B    �  u  ?  �  @  u   A  �   C  	�  ��  	e  ��  	�  ��  	�  	m   I  �   z  	�  	�  	�  	m   	�  	�  �   �   
R  
4�  6  
6m    �  
7m    �  �  5  4   
�  �  �  ��   i  �   �  �   .  B    �  .   	  9  9  C  �  N  N  X  �  c  c  m  y	  x  x  �  
�
  ��  �  ��   `	  ��  �  ��    �   �  �  �  
S  �&  {
  ��   	  ��  �   �  q  @  �  �   �  �  +  Z  6  6  @  C  K  K  U  �  `  `  j  �  u  u    �	  �  �  �  f  �  �  �    �  >  �  S  �  h  �  }  �  �  �  &  �  ;    P    e    z  "  �  -  �  8  I  S  B   @ C  '  S  (  S  	
  -�   	K  .�   -   �  B    d   P   �  b   I  t   h  �  
�  �  $  !�    �  w�  �  �  �  .  �   :  �0   �     B    �  0  B    �  @  B    
r  �Y  ,   ��    @  	�  �Y  	�  �Y  �  Lm   
  �.�  buf /�   +  0m    ��	  1;   �;	  2�  � �   �  B   � (  �  h�9W  �   :   
  <t  P  =�  �  ?  0	  @m   $�1  Am   (�9  B�  ,�key C;   0��
  DW  4� �   g  B   1 
  ��  �  ��    �   ��     ��    	  �g  W   m   /�  �  ~�  c   )  o  �   �   q  �   	c  Fm   	�	  -  �  /;   	� !     �  e�L      ]       �B	  �  eB	  �h �  �  YIL      D       �t	  B  YB	  �h  �  <B	  �K      �       ��	  !  >B	  �h "�  1;   zK             �#�  d3K      G       �Q  d*  �h  �   �  �  �  �  �L      �        4   �8   �   .  �  �   0  b   %?   N  �  'F   int G  )M   �       ��   R  ��   �   7  �   �  ��;  	n   �x    	   ��   	  ��   	  ��   	�  ��    	�  ��   (
�   �   0
�   �   8
_  �   @
  �   H
F  �   P
  �   X
  s  `
   
y  h
  x   p
]  x   t
�  �   x
k  F   �
�  T   �
"     �
O  �  �
�  %�   �
X  -�   �
_  .�   �
f  /�   �
m  0�   �
t  2-   �
�  3x   �
{  5�  � �  �|  �s  	`  �s   	�  �y  	�  �x    B  �   �   �  8     ;  �   �  8    �  u  ?�  �  @�  u   A�  �   �  �  �y  e  �y  �  �y  �  x   �       �    �   �   R  4S  	6  6x    	�  7x    .  S  �  n  8   @ ^  '  	n  (  	n  �  
"�  �   �  $�   �  2x   �  7x   �  ;x   d   [   �  m   I     �  �  �  .  �$  :  �4   �  $  8    �  4  8    �  D  8    r  �]  	,   ��    D  �  �]  �  �]  �  Lx   &	  �  	a  �   	  �   �  �  
  �.�  buf /�   +  0x    ��	  1M   �;	  2  � �     8   � (    �  h�9�  	�   :�   	
  <x  	P  =  	�  ?�  0	  @x   $�1  Ax   (�9  B  ,�key CM   0��
  D�  4� �   �  8   1   ��  	�  ��    	�   ��   	  ��      ��  �  h:y  dev ;~   	�  <�  	`  =F  	�
  >�  	�  ?�  	,  @�  	  AL  	�  BL  ;vid C�  \pid D�  ^	�	  E�  `	%  F�  a �	  y    �  �  @�F  
�  �	   
o   ��  
J  �?   	
  �?   

m  �M   
�  �~  
~  �x   
�  �x   
�  ��   
	  ��   (

  �	  0
�  �x   8
k
  �	  < �  �  \  8    �   l  8    d  �\  �  �x   P  ��   f  �\  �  �x   R  ��   A  �r  
1  ��   
@
  ��  
{  ��  
[  ��  
�  ��  
0
  ��  
i	  ��  
�
  �  
�  �  

�  �  
  
�  
r  �  
�  �  
�  �     ��  �  M   R�     5    �  {  �  q   �	  ��  
~  �M    
�  �M   
�  �~   �	  ��  	  	   F   r  ?   �  (	  !8    �
  @+�	  	n  ,�   	�  -�	  	<  .�   		  /�   key 0M   4	�  1  8	-  2  9	�
  3  :	\
  4  ; �  C  (*�	  	n  +�   	�  ,�	  	�
  .�	  	  /   key 0M   $   (	  "W   x   /D
  #�  ~#�  c   )  o  �   �   q  �   c  Fx   P
  3  $�  4  	� !     $[  ;M   	$ !     $�  <�  	0 !     %g  �M   T      h       �'  &�  �M   �L'Q  ��  �X'�  �M   �T(6T      0       )%   '  �h(6T             )�   -  �`   �	  �  %}  �'  �S      f       ��  &B  ��	  �H'Q  �  �X(�S      2       '%  �'  �h(�S             '�  �-  �`   %
  �'  `S      U       �/  &[  �M   �L'Q  �  �X(tS      "       'J  �'  �h(tS             '�  �-  �`   *�  �x   sQ      �      ��  &�  �M   �L'J  �'  �`(�Q            '�  �x   �\()R      �       '  ��	  �h   *�  �  Q      Z       ��  &'  �x   �l *�  {'  �O      �      ��  &  {�	  ��&B  {�	  ��'!  }  �O'%  ~'  �P'Q  �  �X+�O             j  '�  �-  �` (KP      �       '0  �'  �h  *�  h'  �N      �       ��  &  h�	  �X&B  h�	  �P,a j'  �h -W  cM   �N             �%�  XM   tN      9       �0  'Q  Z�  �h'�  [M   �d .	  L�M      �       ��  &�  Lx   �L'K  N�  �X(�M      c       '%  P'  �h(�M             '�  P-  �`   %5  >M   vM      h       �6  &�  >x   �L'Q  @�  �X'�  AM   �T(�M      0       '%  D'  �h(�M             '�  D-  �`   /�  d/M      G       �b  &Q  d�  �h 0*  S�L      E       �&N  S�  �h&l  S�  �`  �   E  �  �  �  �T      j#      �  4   �8   �   .  �  �   0  b   %?   N  �  'F   int G  )M   �       ��   R  ��   �   7  �   �  ��;  	n   �x    	   ��   	  ��   	  ��   	�  ��    	�  ��   (
�   �   0
�   �   8
_  �   @
  �   H
F  �   P
  �   X
  s  `
   
y  h
  x   p
]  x   t
�  �   x
k  F   �
�  T   �
"     �
O  �  �
�  %�   �
X  -�   �
_  .�   �
f  /�   �
m  0�   �
t  2-   �
�  3x   �
{  5�  � �  �|  �s  	`  �s   	�  �y  	�  �x    B  �   �   �  8     ;  �   �  8    �  u  ?�  �  @�  u   A�  �   �  �  �y  e  �y  �  �y  �  x   �       �    �   �   �   >  8    �   N  8    W   x   /�  �  ~�  c   )  o  �   �   q  �   c  Fx   R  	4�  	6  	6x    	�  	7x    �  �  �  �  8   @ �  '  
�  (  
�  �  "
  �   �  $�   �  2x   �  7x   �  ;x   d   [   �  m   I     Շ  �  ׇ  .  ؗ  :  ٧   <  �  8    G  �  8    R  �  8    r  ��  	,   �]    �  �  ��  �  ��  �  Lx     �'  	�  ��    	�   ��   	  ��      ��  &	  W  	a  W   	  W   2  
  �.�  buf /�   +  0x    ��	  1M   �;	  2�  � �   �  8   � (  �  h�95  	�   :2   	
  <�  	P  =�  	�  ?]  0	  @x   $�1  Ax   (�9  B�  ,�key CM   0��
  D5  4� �   E  8   1 V  ej  	�  hM    	  kM    �  )r�  	�  uM    	�  {>  	�  ~F   $	�  �F   &	w  �?   ( C  (*�  	n  +2   	�  ,�  	�
  .{  	  /�   key 0M   $ �  �
  @+{  	n  ,2   	�  -�
  	<  .�   		  /�   key 0M   4	�  1�  8	-  2�  9	�
  3�  :	\
  4�  ;   �   �  8    d  ��  �  �x   P  ��   f  ��  �  �x   R  ��   A  ��  
1  �<   
@
  �<  
{  �G  
[  �<  
�  �<  
0
  �<  
i	  �<  
�
  G  
�  G  

�  G  
  
<  
r  <  
�  <  
�  <   �	    ��    �  M   R�     5    �  {  �  q   �	  �	  
~  �M    
�  �M   
�  ��   �	  �+	  1	   <	  !<	   B	  �  @��	  
�  ��	   
o   �<  
J  �?   	
  �?   

m  �M   
�  ��  
~  �x   
�  �x   
�  �	   
	  ��   (

  ��	  0
�  �x   8
k
  �
  < �  ?   �  
  "8    �  h:�
  dev ;<   	�  <B  	`  =<	  	�
  ><  	�  ?<  	,  @<  	  AH  	�  BH  ;vid CG  \pid DG  ^	�	  E<  `	%  F<  a 
  �  -<  	�	  .<   	�  /<  	(  0<  	�  1<  	�  2<  	?  3<  	�  4<  	�  5<  	�  6G  	�  7G  
 �  �  <  X  8    #�  BM   	� !     $\  ��U      4"      ��  %B  ��  ��x%�  ��   ��x%`  ��   ��x%s  ��  ��x%I  �M   ��w&�  �M   ��x'mes ��  ��(�W      `         &k  �M   ��x (%X      :      L  &S  �j  ��{&�  �M   ��x (�Y            �  &k  �M   ��x&B  ��  ��x&J  ��  ��z ([      �       �  )�  
M   ��x (�[      G      �  )�  M   ��x))   E  ��z)
  �	  ��y*cmd �	  ��y*buf  �	  ��z*p !�  ��z(:\      �      M  *id <�  ��z (_            �  )�  ]M   ��x)`  ]M   ��x)�  ^x   ��x)�  _�   ��z +�a      e      )  �x   ��x  (>d            ,  )�  ��   ��x)  ��   ��x)  �8   ��x)O  �8   ��y)�  �8   ��z (Vf      [      �  )S  �j  ��z)�  ��  ��{)�  ��  ��~)[  ��  ��z*i �x   ��x)�  ��   ��y*key �M   ��x (�h      q      4  )�  �  ��{)�  �  ��~)[  �  ��z*i x   ��x)�  �   ��y)  x   ��z)J  �  ��z (rk      �      �  )�  �  ��{)�  �  ��~)[  �  ��z*i x   ��x)�  �   ��y)�  x   ��z (lm      �      l  )�  ,�  ��{)�  ,�  ��~)[  ,�  ��y*i ,x   ��x)�  ,�   ��y*v .�
  ��z)�  /x   ��y)J  1�  ��y+�n      �      )�  7�
  ��z)Q  9.  ��~  (4q      �      �  )�  R�  ��{)�  R�  ��~)[  R�  ��y*i Rx   ��x)�  R�   ��y (�r      K      T  )�  ^�  ��{)�  ^�  ��~)[  ^�  ��y*i ^x   ��x)�  ^�   ��y)  `x   ��z)  d{  ��y +cu      �      )�  r�  ��{)�  r�  ��~)[  r�  ��y*i rx   ��x)�  r�   ��y  M   �   �  8   ? �  �   �  8   8   O �   �  8    �  ,�  NM   �T      �       �:  %v  Nx   �\&  P8   �h -�  E�T             �f  %�  EM   �l .1  *�T      O       ��  /buf *�  �h/val *x   �d <   �   �  �  �  �  �w      �      �   4   �8   �   .  �  �   0  b   %?   N  �  'F   int G  )M   �       ��   R  ��   �   7  �   �  ��;  	n   �x    	   ��   	  ��   	  ��   	�  ��    	�  ��   (
�   �   0
�   �   8
_  �   @
  �   H
F  �   P
  �   X
  s  `
   
y  h
  x   p
]  x   t
�  �   x
k  F   �
�  T   �
"     �
O  �  �
�  %�   �
X  -�   �
_  .�   �
f  /�   �
m  0�   �
t  2-   �
�  3x   �
{  5�  � �  �|  �s  	`  �s   	�  �y  	�  �x    B  �   �   �  8     ;  �   �  8    �  u  ?�  �  @�  u   A�  �   �  �  �y  e  �y  �  �y  �  x   �       �    �  x   �    �   �   R  4i  	6  6x    	�  7x    D  i  5  	F   �  
��  	�  
�t   	i  
��     �   �  8      �   	  �  �  �  �  �  �  �  �  �  �  �  y	        �
  �U  	�  �t   	`	  �  	�  �  	  �       Z  S  ��  	{
  �t   		  ��  
�   �  
q    
�  �   e  e  �  Z  �  �  �  C  �  �  �  �  �  �  �  �        
  �	        f  *  *  4  �  ?  �  J  �  U  �  `    k  U  v  �  �  �  �  �  �  �  �    �    �  /  �  �  �  8   @ �  '  �  (  �  
  -�   K  .�   ?   !  8    �  "-  �   �  $-  �  $�   �  2x   �  7x   �  ;x   d   [   k  �  m   I     h  �  �  �  	$  !�    �  w{  ��  �  ��  .  ��  :  �
   k  �  8    {  
  8    �    8    r  �3  	,   ��      �  �3  �  �3  &	  s  	a  s   	  s   N  (    ��  	�  ��    	�   ��   	  ��      ��  �   �  8    d  ��  �  �x   P  ��   f  ��  �  �x   R  ��   �  x   A  ��  
1  �k   
@
  �k  
{  �{  
[  �k  
�  �k  
0
  �k  
i	  �k  
�
  {  
�  {  

�  {  
  
k  
r  k  
�  k  
�  k   �	    ��    �  M   R1	     5    �  {  �  q   �	  �f	  
~  �M    
�  �M   
�  ��   �	  �r	  x	  �	  �	   �	  �  @�@
  
�  �@
   
o   �k  
J  �?   	
  �?   

m  �M   
�  ��  
~  �x   
�  �x   
�  �f	   
	  ��   (

  �F
  0
�  �x   8
k
  �L
  < �  ?   1	  [
  8    �
  @+�
  	n  ,N   	�  -q  	<  .�   		  /   key 0M   4	�  1y  8	-  2y  9	�
  3y  :	\
  4y  ; �  h:q  dev ;�   	�  <  	`  =�	  	�
  >k  	�  ?k  	,  @k  	  A  	�  B  ;vid C{  \pid D{  ^	�	  Ek  `	%  Fk  a �
  �  -�  	�	  .k   	�  /k  	(  0k  	�  1k  	�  2k  	?  3k  	�  4k  	�  5k  	�  6{  	�  7{  
 �  �  k    8    W   x   /`  �  ~�  c   )  o  �   �   q  �   c  Fx   :  �x   ��            ��     ��  ��!err �x   �L"�  �q  �P#]  �n�      "  �w  �\ [
  �  �x   �      �       �   �  �q  �h �  ix   Â      C      �c   �  iq  �X$key iM   �T"  kx   �l h  Lx   ��            ��   �  Lq  �X$key LM   �T!res Nx   �d"�  Ok  �c �  7x   ��      �       �   �  7q  �X$key 7M   �T!res 9x   �l �  x   �      C      �q   �  q  �X$key M   �T!res x   �d"�  k  �c �  x         �       ��   �  q  �X$key M   �T!res x   �l %�  �x   >~      �       �  &�  �q  �X&�  �  �P'key �M   �L(res �x   �l k  %#  �x   {            ��  &�  �q  �X'key �M   �T&  ��  �H(res �x   �l)�  �k  �k w  *�  ��z      C       ��  &�  �q  �h %  �x   z      �       �  &�  �q  �h'buf �  �`&0  �x   �\ v  %�  Wx   <x      �      ��  &�  Wq  �X'buf W  �P&0  Wx   �L&�  Wk  �H)U  Yx   �l(res Zx   �h +1  *�w      O       �'buf *  �h'val *x   �d  �     �  Z  �  ��      D       %  4   �8   �   .  ?   �  K   �   0  b   %?   N  �  'K   int G  )W   �       ��   R  ��   �   7  �   �  ��E  	n   ��    	   ��   	  ��   	  ��   	�  ��    	�  ��   (
�   �   0
�   �   8
_  �   @
  �   H
F  �   P
  �   X
  }  `
   
�  h
  �   p
]  �   t
�  �   x
k  K   �
�  ^   �
"   �  �
O  �  �
�  %�   �
X  -�   �
_  .�   �
f  /�   �
m  0�   �
t  2-   �
�  3�   �
{  5�  � �  �|  �}  	`  �}   	�  ��  	�  ��    L  �   �   �  8     E  �   �  8    �  u  ?�  �  @�  u   A�  �   �  �  ��  e  ��  �  ��  �  �   �       �    �  �   �    �   �   R  	4s  	6  	6�    	�  	7�    N  s  5  
K   �  ��  	�  �~   	i  ��   �  �   �  8    �  �   	  �  �  �  �  �  �  �  �  �  �    y	        �
  �_  	�  �~   	`	  �  	�  �  	  �   "  "  d  S  ��  	{
  �~   		  ��  
�   �  
q  $  
�  �   o  o  �  Z  �  �  �  C  �  �  �  �  �  �  �  �  
  
    �	      )  f  4  4  >  �  I  �  T  �  _  �  j    u  _  �  �  �  �  �  �  �  �  �    �  $  �  9  �  �  �  8   @ �  '  �  (  �  
  -�   K  .�   ?   +  8    �  "7  �   �  $7  �  $�   �  2�   �  7�   �  ;�   d   e   �  w   �  I  �   h  �  �  �  	$  !�    �  w�  ��  �  ��  .  �  :  �   u    8    �    8    �  $  8    r  �=  	,   ��    $  �  �=  �  �=  &	  }  	a  �   	  �   X  X  (    ��  	�  ��    	�   ��   	  ��      ��  �  h:h  dev ;m   	�  <x  	`  =5	  	�
  >u  	�  ?u  	,  @u  	  A;	  	�  B;	  ;vid C�  \pid D�  ^	�	  Eu  `	%  Fu  a �	  h    s  �  @�5	  
�  �   
o   �u  
J  �?   	
  �?   

m  �W   
�  ��  
~  ��   
�  ��   
�  ��   
	  ��   (

  �  0
�  ��   8
k
  �%  < ~  u  K	  8    �   [	  8    d  �K	  �  ��   P  ��   f  �K	  �  ��   R  ��   �  �   F  W    

  �    �  �  �  �  o  �  !A  ")!  #�  )l   *�  0 1  W   F)
  �  ��    X  W   TZ
      1   �  �         W   g�
  �!   R    �    �  W  �  	g  
�  %  �  0@  1 A  �  
1  �u   
@
  �u  
{  ��  
[  �u  
�  �u  
0
  �u  
i	  �u  
�
  �  
�  �  

�  �  
  
u  
r  u  
�  u  
�  u   �     
1  u   
@
  "u  
�  (u  
_   1u  
�  4�  
  7u  
�   ;u  
�  >u  
m  B  
x  E�      F   `  (M�  
1  Ou   
@
  Tu  
  Wu  
x  Zu  
�  ^u  
�  au  
  eu  
q  iu  
�  lu  
J  p�  
m  t  
x  w�         s  }�  
�   ��   
�   ��    �  �    (��  
1  �u   
@
  �u  
�  ��  
|  �u  
�   �u  
�  �u  
_   �u  
�  �u  
z  ��  
m  �  
x  ��     �  <!  �   
�  ��   
�  ��  
�  ��  
�   ��  rc ��  
  ��   �  2  �  2    �s  R   �   �  �   �!  �  ~�   }�  |A  {�  z9  y�  x "  w�  v�!  u?  t�  � �  W   R�     5    �  {  �  q   �	  ��  
~  �W    
�  �W   
�  ��   �	  �      5	     ?   �  4  8      Y  q�   W   �a  �!  "   �  �F  �
  @+�  	n  ,X   	�  -�  	<  .�   		  /�
   key 0W   4	�  1�  8	-  2�  9	�
  3�  :	\
  4�  ; �   W   �   /4  �  ~�  c   )  o  �   �   q  �   c  F�   m  !0  /4  	� !     "�  3X  	@ !     "�  5:  	� !     R   �  8    �  "K!  9�  	 �      #�!  k�   ��      �      �9  $�  k  �X%ep ku  �T$l  k9  �H$0  l�   �P$m  l�   �D&!  n�   �`'ret o�   �d u  #�  �   R�      1      �  $!  �   ��$�  x  ��$�
  9  ��$�  9  ��$,  9  ��&�  m  �X&N  �  �P&U!  �  �`&�     �H'ret �   �@(j�      �       &#!  /�   �D    #�   ��   {�      �      ��  $�  �  �H$!  ��   �D&�  �m  �`'ret ��   �T&  �  �X&  ��   �P )  �S�      (       �#�  ��   ��      �      �  'cnt ��   ��~'idx ��   ��~&  ��   ��~&�  �  ��~&]!  �?  ��~&�  �x  ��~&�  ��  ��~&]  ��  ��~&  �"  ��~*<�      �      �  &	  ��
  ��~(|�      :      &�  �"  ��  (�            &Q  ��  ��~(B�      �       &  �?  ��~(B�             &�  �2  ��~    m  �   2  8   ? }  #K  i�   N�      N      �y  $  i?  �X'err k�   �l +�  ��   �      G      ��  ,cnt ��   ��},err ��   ��}!]  ��  ��}!  �"  ��~,idx Â   ��}!  Â   ��}!�  �  ��}!]!  �?  ��~!�  �x  ��}!Q  Ȃ  ��}!   Ȃ  ��~&�  ;X  ��~*E�            �  !  �?  ��~(E�             !�  �2  ��~  *Ώ      i      �  !	  �
  ��~(�      f      !�  �"  ��  *��            H  &  @?  ��~*��             &  &�  @2  ��~ ($�      �       'rc N�   ��}  (6�      �       &  W?  ��~(6�             &�  W2  ��~   +�  ��  F�      �       �  -dev �m  ��~!�  �x  ��~!	  ��
  ��!  �"  ��(��      U       !  �?  ��~  +�  ��   ��      �       �:  ,v �:  �h    +�  t�   ً      �       ��  -ctx t�  �h-dev tm  �`.�  ua  �\.	  u�   �P   /�   `�    �      �       �  -dev `m  ��.P!  `  ��!	  b�
  �P!  c�   �L(;�      P       ,i hW   �H  �  +,  A8   <�      �       �x  .q  A  �X-str A�   �P,i B�   �h,len C�   �l 0h!  �   ۉ      a       ��  $�    �h$�  u  �d$j  �  �`$l    �X$~  �   �T 1�  t��      K       �   .�  t�  �h.�   t�  �` 2�  dI�      G       �L  .Q  d�  �h 2*  S�      E       ��  .N  S�  �h.l  S�  �` 3=  @��      C       �.N  @�  �h.l  @�  �`  %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   :;  7 I  :;   :;I  :;   :;I  '   I   '  >I:;  (   (   .?:;'I@�B  4 :;I   .:;'@�B  ! :;I  " :;I   %   :;I  $ >  $ >  & I      I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   :;  7 I  :;   :;I  :;   :;I8   :;I8  ! I/  5 I   :;I8  >I:;  (   (   :;    :;I  !>I:;  "'  # I  $! I  %4 G:;  &4 :;I?  '.?:;'@�B  (4 :;I  )4 :;I  *
 :;  +  ,  -4 :;I  .. ?:;'@�B  /.?:;'I@�B  0 :;I  1.:;'I@�B  2 :;I   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I  >I:;  (   (    :;I8  4 :;I  .?:;'I@�B   :;I  4 :;I  U   %  $ >   :;I  $ >      I  & I   :;I  	4 :;I?<  
4 :;I?<  :;   :;I8   :;I8   :;  I  ! I/   <  !   :;  7 I  >I:;  (   (   (   >I:;  :;   :;I  :;  :;   :;I8   :;I8   ! I/  ! :;I8  "(   #4 :;I?  $.?:;'I@�B  % :;I  &4 :;I  '4 :;I  (  ).?:;'@�B  *.?:;'I@�B  +4 :;I  ,4 :;I  -
 :;  ..?:;'@�B  / :;I  0. ?:;'@�B  1.:;'@�B   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   I  I  ! I/   :;   <  4 :;I?<  4 :;I?<  !   7 I  >I:;  (   (   4 G:;  4 :;I  .?:;'I@�B   :;I  . ?:;'@�B  .?:;'@�B   :;I     4 :;I     !.:;'I@�B   %  $ >   :;I  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  '   I  :;   :;I  >I:;  (   (   4 G:;  .?:;'I@�B   :;I  4 :;I  .?:;'@�B  4 :;I   I   %   :;I  $ >  $ >      I  & I  I  	! I/  
:;   :;I8   :;I8   :;   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I  :;   :;I8   :;I8  ! I/   :;I8  :;   :;I  >I:;  (   '   I   ! I  !>I:;  "(   #4 :;I?  $.?:;'I@�B  % :;I  &4 :;I  '.?:;'I@�B  ( :;I  )4 :;I  *.?:;'I@�B  + :;I  ,4 :;I  -. ?:;'I@�B  .. ?:;'@�B  /U  04 :;I  1.?:;'I@�B  2  3.?:;'@�B  4 :;I  5.:;'@�B   %  $ >   :;I  $ >      I  & I  4 :;I?<  	4 :;I?<  
:;   :;I8   :;I8   :;  I  ! I/   <  !   7 I  :;   :;I  :;   :;I8   :;I8  ! I/   :;I8  >I:;  (   (   4 :;I?  .?:;'@�B   :;I   .?:;'I@�B  !4 :;I  ". ?:;'I@�B  #.:;'@�B   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I  :;   :;I8   :;I8  ! I/  5 I   :;I8  :;   :;I  >I:;  (   '    I  !! I  ">I:;  #(   $4 :;I?  %.?:;'I@�B  & :;I  '4 :;I  (  )4 :;I  *.?:;'I@�B  +  ,4 :;I  -. ?:;'I@�B  ..?:;'@�B  /.:;'@�B  0.:;'@�B   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   >I:;  (   (   7 I  :;   :;I  :;   :;I8   :;I8  ! I/   :;I8  :;   :;I  >I:;   '  ! I  "! I  #4 :;I?  $.?:;'@�B  % :;I  &4 :;I  '4 :;I  (  )4 :;I  *4 :;I  +  ,.?:;'I@�B  -.?:;'@�B  ..:;'@�B  / :;I   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I  :;   :;I  >I:;  (   '   I  ! I   :;I8  >I:;  (   .?:;'I@�B    :;I  !4 :;I  "4 :;I  #
 :;  $ :;I  %.?:;'I@�B  & :;I  ' :;I  (4 :;I  )4 :;I  *.:;'@�B  +.:;'@�B   %   :;I  $ >  & I  $ >      I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I   :;I8  :;  >I:;  (    :;I8   :;I  (   '   I  ! I  >I:;   >I:;  !4 :;I  "4 :;I?  #.?:;'I@�B  $ :;I  % :;I  &4 :;I  '4 :;I  (  ). ?:;'@�B  *  +.?:;'I@�B  ,4 :;I  - :;I  . :;I  /.:;'I@�B  0.:;'I@�B  1.:;'@�B  2.:;'@�B  3.:;'@�B      �  �      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/bits/types /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  signal_handler.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   __sigset_t.h   time.h   __sigval_t.h   siginfo_t.h   signal.h   sigaction.h   unistd.h   getopt_core.h   stdint-uintn.h   in.h   common.h    log.h      	*      � /��v.�[Y�.����wב�v �Y Z� u   R  �      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/bits/types /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  list.h    accept.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   struct_timeval.h   select.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   unistd.h   getopt_core.h   stdint-uintn.h   common.h    sock_info.h    log.h    stlink_connection.h    list_stlink.h    time.h   libusb.h   stlink_mgt.h      	U      ����.v��� h S ��Y5K �YYYY��崟� � [Z"v|(� / � U p C �� �]{��.�ɑ� �ʒ\ʠ\� ���Z[� �Y|/��Mz� �&�w� �Y	�Q��Y�0� ��� �X �<�f! W   �  �      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  cmdline.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   unistd.h   getopt_core.h   stdint-uintn.h   common.h    log.h    getopt_ext.h     	F%      >��v&$f_. ���V��Z�Z �Yu[ � � � t� � � t �Z ��� ���0 � � � t� � � t �* ] ,XYYYYYY]��]�Y t   �  �      /usr/include/x86_64-linux-gnu/bits /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include /usr/include/x86_64-linux-gnu/bits/types /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  list.h    common.c    types.h   stddef.h   unistd.h   getopt_core.h   libio.h   stdio.h   sys_errlist.h   struct_timeval.h   select.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   stdint-uintn.h   netdb.h   common.h    sock_info.h    socket_type.h   log.h      	(      � ����O<PA�/B��4g�+�n��uv� �Y �[Yuuuz �*�s���[�Y[ �]> �-�g��[\ ��Zg#��'g�#�'g�#'g�#��gy#�\ �Y/�Y�_ �Y����uY�1��/�v � �~X ���%�� �[ �Yu^� �\�� �ػ� �� y� .
� �Y	< 栭�� �,	+�ɑʡ�'�̻�Y��Y �� u�|�O� �X�#g�h �Y�g�hgYi��=-iK5��y�����Y(U6ʹ%�ɟ ����u� ��r]� �ʼ�Y��>�u� �Y�ɒu� �ɓ ��Gt �= gX�Q  � ���=;�g�gY�����ׯ�� �'K �   H  �      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include/x86_64-linux-gnu/bits/types /usr/include /usr/include/x86_64-linux-gnu/sys  log.c    stddef.h   types.h   libio.h   FILE.h   stdarg.h   <built-in>    stdio.h   sys_errlist.h   struct_timeval.h   time.h   log.h      	|9      � ��=g�7K^X#��-��x �X#�$-�uE�[�-�>l �L�ػ?�hu�Y 0   V  �      /usr/include/x86_64-linux-gnu/bits /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  main.c    types.h   stddef.h   libio.h   stdio.h   sys_errlist.h   unistd.h   getopt_core.h   time.h   signal.h   stdint-uintn.h   in.h   common.h    log.h    time.h     	g=      6<�	 ����wY�v�vi � ����� �- � �����]��� � xX.��� � Zp. i��ui�i�u[�� �Z�Z �YɑY�[ �Y_ �YZ �Yw	t= �   �  �      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  list.h    stlink_api.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   signal.h   unistd.h   getopt_core.h   stdint-uintn.h   in.h   common.h    sock_info.h    stlink_driver.h    stlink_connection.h    list_stlink.h    time.h   libusb.h   stlink_mgt.h    log.h      	�A      � �0!��K<� � / � � J����=1�$�vZ1� �+��!1��� �,� b �� ��Y1�$�� �&� b �� ��Y1vv�� h E ��Y1K�2�׭ �"���/ �7�v�Z3�g�Z1�٭ �+i J�� �8��g � y�
X ���q�X �����i�Xu �v �' ��^�$ K1LY@Lu1��u�[ ���6��v t��s� t�׼u�Z����)=.�� � W ��K �   �  �      /usr/include/x86_64-linux-gnu/bits /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  list.h    sock_info.c    types.h   stddef.h   unistd.h   getopt_core.h   libio.h   stdio.h   sys_errlist.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   stdint-uintn.h   common.h    sock_info.h    log.h      	3K      � �0!��F<K�	.��u �v ��Y�ׯK5�� � � !5� �+��! �   �  �      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  list.h    stlink_connection.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   signal.h   unistd.h   getopt_core.h   stdint-uintn.h   in.h   common.h    sock_info.h    stlink_mgt.h    libusb.h   time.h   list_stlink.h    stlink_connection.h    log.h      	�L      � ����D�0!��S<vv�� �� G ��=1��� �� �$ ~ ��?Lv � I ��=1K�1��u��׃ �$L �$K2�K�0�� �Y�K z. ��M� �"g�u �( �׻�K2� ��� ��u5� ��ح��L �(� �&� ��� ���� �Z �����Y2w�� c ��Y1���� c ��Y1vv�� �� G ��=    	  �      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  util.h    stlink_tcp_cmd.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   log.h    time.h   signal.h   unistd.h   getopt_core.h   stdint-uintn.h   in.h   common.h    list.h    sock_info.h    stlink_driver.h    stlink_connection.h    list_stlink.h    time.h   libusb.h   stlink_mgt.h      	�T      *�!!!�<u��@w��0�.�0�"K
.5� �#�u �����|X!�#�� �%���|X"�#��u �-���|X(� �1�#	�(�#��ˢ�#�|X! ��#�
��� �7ʟY�0 �"�j����}X"�#�� ��ʡu���}X(��#���"� ��!�"[h�"�� �� �#�!=�!! �\��g��"�%,�!&��#���  !��4�y�	.  !ؾ���.� ��# �!"�� �� �� � A �t�~X"w�# � ( � � � � � � ���~X# �&� �+Y�f�~X# B ~ �� �&,�q>r2 �+ �& �+ � Y �f�~X# B ~ ��) �<� �0$ �&� � + Y � f�X# B ~ ��) �,/�� �- 	� 	Y 	� f�X# B ~ ��)> � .u �� �&.[ �  �� ���K�=s=sKsl5.� � + Y 5fMX# B ~ �� �&�� � + Y )fYX# B ~ ��) �&> �� �*#�� � + Y fmX# B ~ ��#*&� � + Y 	fzX ��) ��Yh" Q   �  �      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  util.h    stlink_mgt.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   unistd.h   getopt_core.h   stdint-uintn.h   list.h    common.h    time.h   libusb.h   list_stlink.h    stlink_mgt.h    log.h      	�w      *�!!!�(<uuvuY��Y��. �Yw ��h1 �Y�h- �Y� ��w=2/uY��Yw- �YvY2���@2uY��L � �#�L"g�/)=���''# � � �K�zX`�w�X�L"g������僄''��Y21uY���L�g� �'=2�uYw���L� ��=2��uY��g� �ٻ= ��gZ� �� =�x�uYw���L� ��=2��uY��g� �ك=gZ� �� =�x�uY� � ���=g����K� ��gZv �#Z2� �� �YK ���Y2��uY[�Y\� ��M3gY^u��E ��E ��E ��Z ��W\��v�� �� Y� A   �  �      /src/staging/libusb/linux64/include/libusb-1.0 /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  list.h    libusb.h   libusb_mgt.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   unistd.h   getopt_core.h   stdint-uintn.h   common.h    stlink_mgt.h    time.h   list_stlink.h    log.h      	��      � �׼�
<����D�0!��	<�/"/�<�:us/�r.��k � = J�k � $ Jk�Y1��Yg� �� r Jz �( Y�ygg ��vh ����Y2����u �^ �XY2 �Z�Y��w�Y]��
t�/� �,�u �$ �(g/ v� <� ���2� � :Z- � 7[2�/ ��?Y ����u�Y�0�Yv!"(�Y�� �E �9� ��� ��Y� �Y�(Y� �>Y� �. �� ��0@ v  t�  � �%$�! �,� XY �$ �9gu0� �( �$K� o0 �<$� � 0  � / w� �< �%g]�%) � YZ � YZ � Y0 � %0 � (t.????"=3��ux �Y� ���2� � :Z- � 7Z2�/ ��?Y ����u�Y�0�Yv!"(�0 �DY� �9Z� ��� �D0@ v  t�  �>/�Y �$ �9g z. <u[K!�A��v� �"Yg� �( ��Y �#�g �(�g ��=^���uuvug f� �(� �(����/�h����� ht J<� �#��> � Y0 � Y0 � Y0 � Yw.???" �(x�=`��u(� ��g �Y�g �" �(�� �&= __off_t _IO_read_ptr _pkey _chain _shortbuf __in6_u size_t si_addr __sigval_t si_errno log_levels __uint8_t sa_flags _IO_2_1_stderr_ _IO_buf_base __sighandler_t _lower long long unsigned int LOG_LVL_STLINK _arch LOG_LVL_DEBUG long long int listen_interface accept_context _fileno _IO_read_end _sigchld __u6_addr16 __u6_addr32 _IO_backup_base si_stime _IO_buf_end _cur_column _upper si_overrun _bounds install_ctrl_handler _old_offset in6addr_loopback GNU C99 7.5.0 -mtune=generic -march=x86-64 -g -g -g -std=gnu99 -std=gnu99 -std=gnu99 -fstack-protector-strong si_addr_lsb si_sigval __uint32_t __off64_t si_pid debug_level LOG_LVL_WARN _IO_marker stdin LOG_LVL_MAX __val si_utime _IO_FILE_plus _IO_write_ptr /src/work/stlinkserver/linux64/src _sbuf short unsigned int si_uid siginfo_t _IO_save_base sival_int LOG_LVL_INFO tz_minuteswest __clock_t _lock _sigsys _flags2 stdout _syscall _IO_2_1_stdin_ _pad optarg _sigpoll optind _sifields _IO_write_end address_family _IO_lock_t in6addr_any _IO_FILE si_tid __environ stderr _pos signal_handler.c _markers _sigfault _Bool unsigned char _addr_bnd __pid_t short int _call_addr LOG_LVL_ERROR LOG_LVL_LIBUSB _vtable_offset _IO_2_1_stdout_ LOG_LVL_OUTPUT si_status optopt __uint16_t tz_dsttime __u6_addr8 opterr __uid_t __sigaction_handler si_signo _IO_read_base _IO_save_end _sys_siglist siginfo sa_sigaction sa_mask __pad0 __pad1 __pad2 __pad3 __pad4 __pad5 _unused2 sa_restorer __sigset_t si_fd _timer LOG_LVL_SILENT sa_handler sival_ptr si_band _IO_write_base si_code sockaddr_ax25 sin6_flowinfo libusb_device_handle interval s_info trace_ep LIBUSB_TRANSFER_ERROR program_invocation_short_name sa_data LIBUSB_TRANSFER_OVERFLOW __fd_mask tx_ep loop sin6_scope_id sockaddr_ns getdate_err databuf LIBUSB_TRANSFER_CANCELLED _sys_nerr bcdDevice idProduct prev __d0 iManufacturer LIBUSB_TRANSFER_COMPLETED read_fd_set sockaddr_ipx __timezone bDeviceClass in_addr_t iProduct bcdUSB sockaddr SOCKET stlk_dev libusb_transfer_status num_iso_packets dev_handle libusb_transfer opened sin_family in_port_t bDeviceSubClass sin6_port timeval sin_zero s_addr data_size sa_family_t libusb_device_descriptor sockaddr_inarp tv_usec sin6_addr LIBUSB_TRANSFER_STALL sockaddr_iso stlink_usb_device non_blocking_accept_main iSerialNumber accept.c sin_addr sockaddr_dl __daylight sockaddr_at socks_in_fd_set user_data list_head total_recd transaction_in_progress socket_error sin_port bMaxPacketSize0 sockaddr_eon connection_list sockaddr_un send_offset b_exit libusb_iso_packet_descriptor fw_major_ver libusb_transfer_cb_fn libusb_device nth_sock data_buffer program_invocation_name bDeviceProtocol bDescriptorType ask_to_kill to_reopen __d1 iso_packet_desc sin6_family fds_bits client_name HEART_BEAT_INTERVAL exit_server ready closed_for_refresh stlink_usb sockaddr_in idVendor rx_ep tv_sec cmdbuf dev_desc LIBUSB_TRANSFER_TIMED_OUT asso total_sent serial stlink_assoc is_socket_listening __tzname timeout is_list_empty __suseconds_t __time_t LIBUSB_TRANSFER_NO_DEVICE restart_after_error actual_length __mptr sa_family _sys_errlist recd_data bNumConfigurations g_listening_sock_nb fw_jtag_ver bLength is_fd_close_recd endpoint sockaddr_in6 trans sockaddr_x25 long_options version_flag cmdline.c help_flag option_index option auto_exit_flag parse_params has_arg argc argv process_accept_event IPPROTO_EGP destroy_listening_sockets common.c ai_addrlen IPPROTO_MTP ai_flags SOCK_RAW IPPROTO_ENCAP ai_next local client_address ai_canonname res1 new_sock IPPROTO_UDP sock_addr SOCK_DCCP SOCK_RDM IPPROTO_IGMP SOCK_SEQPACKET init_sockinfo addr_len __socket_type IPPROTO_IP SOCK_STREAM __ss_align IPPROTO_PIM IPPROTO_GRE IPPROTO_IPV6 __socklen_t create_listening_sockets curr_entry IPPROTO_ICMP IPPROTO_ESP IPPROTO_UDPLITE IPPROTO_MAX IPPROTO_RAW ai_family ai_socktype IPPROTO_RSVP LPSOCKADDR print_address_string hints IPPROTO_DCCP new_sock_info SOCK_NONBLOCK list_add_tail bytes_send IPPROTO_TP new_entry ai_addr expected_size CLEANUP close_socket_env client_address_len timeout_retry SOCK_DGRAM total_received_size IPPROTO_SCTP IPPROTO_PUP IPPROTO_IDP IPPROTO_MPLS non_blocking addrinfo send_data bytes_recd IPPROTO_COMP SOCKADDR_STORAGE psock_info SOCK_CLOEXEC SOCK_PACKET __ss_padding sockaddr_storage p_data_buf IPPROTO_BEETPH get_stlink_tcp_cmd_data IPPROTO_IPIP IPPROTO_TCP process_read_event ai_protocol IPPROTO_AH gp_offset ms_del log_init log_output __builtin_va_list overflow_arg_area handle_log_output_command log_out __gnuc_va_list file reg_save_area format start_delay log_print log.c ms_delay fp_offset log_strings __va_list_tag minor build_ver major get_version_cmd majorStr medium internPtr main_ver minorStr main.c print_version mediumStr tmp_ver rev_ver stlink_close stlink_open_device device_used stlink_get_device_info vendor_id stlink_get_device_info2 stlink_api.c stlink_usb_id enum_unique_id assoc_id delete_stlink_from_list list_to_count stlk_usb stlink_init get_stlink_by_key get_stlink_by_serial_name device_request_2 get_stlink_by_list_index stlink_send_command product_id stlink_get_nb_devices dwTimeOut assoc_list stlink_device_info list_del input_request stlink_usb_list device_id serial_code buffer_size stlink_refresh jenkins_one_at_a_time_hash list_count key_to_find is_item_exist_in_stlink_list sock_info.c alloc_sock_info get_nb_tcp_client sock_info_keys free_sock_info delete_sock_info_from_list del_sock_info make_connection stlink_connection_invalid_usb wanted_client get_usb_number_client assoc_entry new_assoc_index get_nb_client_for_usb get_connection_by_sock usb_key get_tcp_number_client evaluate_auto_kill add_connection connection_count close_connection stlink_connection.c get_connection_by_name already_exists new_connection power_ver size_of_input_cmd prec output_buf usd_dev_id internal_error dev_info_size res1_ver stlink_fw_version tcp_client_api_version bridge_ver res2_ver stlink_tcp_cmd.c connect_id error_convert cmd_answ tcp_cmd_error tcp_server_api_version w_4_uint8_to_buf exclusive_access dev_info process_stlink_tcp_cmd p_answer_size_in_bytes input_buf free_token msc_ver swim_ver g_rwMiscOwner seps stlink_mgt_send_cmd stlink_mgt_get_current_mode stlink_mgt_close_usb stlink_mgt_read_trace_data stlink_mgt_get_version stlink_mgt_open_usb_dbg_if cmdsize error_open stlink_mgt_exit_dfu_mode stlink_mgt_exit_jtag_mode stlink_mgt_dfu_exit stlink_mgt_jtag_exit stlink_mgt_init_buffer stlink_mgt.c stlink_usb_blink_led req_type fwvers result LIBUSB_DT_CONFIG LIBUSB_REQUEST_SYNCH_FRAME LIBUSB_SET_ISOCH_DELAY LIBUSB_REQUEST_GET_CONFIGURATION bAlternateSetting iInterface LIBUSB_DT_STRING LIBUSB_ERROR_INTERRUPTED serial_number LIBUSB_DT_HUB LIBUSB_REQUEST_SET_CONFIGURATION list_move describe bInterval bInterfaceSubClass compute_serial_str LIBUSB_ERROR_NOT_SUPPORTED libusb_mgt.c LIBUSB_REQUEST_GET_INTERFACE LIBUSB_DT_INTERFACE devs LIBUSB_TRANSFER_TYPE_BULK LIBUSB_DT_SS_ENDPOINT_COMPANION libusb_mgt_refresh bNumEndpoints LIBUSB_REQUEST_SET_SEL bInterfaceNumber LIBUSB_TRANSFER_TYPE_BULK_STREAM LIBUSB_DT_REPORT LIBUSB_REQUEST_CLEAR_FEATURE LIBUSB_DT_DEVICE_CAPABILITY LIBUSB_DT_HID LIBUSB_ENDPOINT_OUT LIBUSB_ERROR_OVERFLOW MaxPower hotplug_callback LIBUSB_DT_BOS LIBUSB_DT_ENDPOINT LIBUSB_ERROR_OTHER current_config LIBUSB_TRANSFER_TYPE_CONTROL list_add libusb_descriptor_type b_malloc_err langid bInterfaceProtocol udev wTotalLength wMaxPacketSize bInterfaceClass LIBUSB_REQUEST_SET_DESCRIPTOR micro LIBUSB_ERROR_NO_DEVICE LIBUSB_ERROR_BUSY libusb_mgt_exit_lib errCode LIBUSB_REQUEST_SET_FEATURE LIBUSB_ERROR_TIMEOUT inter_desc libusb_hotplug_callback_handle extra_length libusb_mgt_init_refresh move_entry stlink_found LIBUSB_ENDPOINT_IN usb_delete_list libusb_endpoint_descriptor LIBUSB_TRANSFER_TYPE_INTERRUPT LIBUSB_REQUEST_GET_DESCRIPTOR a_libusb_context LIBUSB_ERROR_NOT_FOUND libusb_transfer_type extra libusb_interface bSynchAddress LIBUSB_REQUEST_SET_ADDRESS libusb_hotplug_event LIBUSB_ERROR_INVALID_PARAM hotplug_handle LIBUSB_SUCCESS LIBUSB_REQUEST_SET_INTERFACE libusb_config_descriptor libusb_endpoint_direction libusb_mgt_real_open libusb_interface_descriptor bNumInterfaces libusb_mgt_remove_device libusb_mgt_claim_interface desc_index bEndpointAddress iConfiguration libusb_mgt_init_lib LIBUSB_DT_DEVICE tmp_entry libusb_standard_request LIBUSB_TRANSFER_TYPE_ISOCHRONOUS libusb_error bmAttributes LIBUSB_DT_SUPERSPEED_HUB bConfigurationValue num_altsetting config_desc nano other_list_entry bRefresh LIBUSB_ERROR_ACCESS stlink_match libusb_mgt_set_configuration transferred if_id ep_id LIBUSB_DT_PHYSICAL libusb_version stlk_pids ep_desc new_stlink libusb_get_string_descriptor LIBUSB_ERROR_IO LIBUSB_ERROR_NO_MEM LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED LIBUSB_REQUEST_GET_STATUS libusb_mgt_bulk_transfer LIBUSB_ERROR_PIPE LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT        Q       d       \                      f                  \      a      �                                                         8                    T                    t                    �                    �                    X
                    �                    (                   	 �                   
 h                    �                    �                                                             ��                    ��                     �                    @�                    P�                    X�                    `�                    p�                    ��                      !                   ` !                                                                                                                                                                            ��                     P                   �              !     �              7     � !            F     X�              m                    y     P�              �    ��                �    *      Z       �    ��                �     U             �    ��                �     � !            �     � !            �     `�      �       �    ��                �     (      E          ��                    � !                � !            "    @�      0       �    � !            .    |9      �       7   ��                >   ��                K    �A      G       T   ��                K    3K      G       `   ��                �     �L      E       K    /M      G       t   ��                �    �T      O       �   ��                �    �w      O       �    �z      C       �   ��                �    ��      C       �     �      E       K    I�      G       �    ��      K       �    ۉ      a       �    � !                 �      �           ��                    ��                   ��                #     X�              4    p�              =     P�              P      �              c    ��              y    �C      �       �    ��             �     =      +       �                     �                     �    Â      C      �    �      �       �    �H                 z      �       !    @ !            1    � !            @                     ^                     j                                          �                             !             �                     �    �      >       �    �(      �       �                     �    � !            �    � !                                                      2      !            >    tN      9       T    P !             [    �?      }       i    �2      ]      |    �      �       �    
       <      �    �B      ]       �    ��              �                     �                     �                                                               7                     J                     �                     \    ;      �      f                     s    _B      N       �    �/            �                     �                     �    �(      "       �                                              �      G      /                     M                     `     �             j    �L      ]       �    zK             �                     �                     �    ً      �       �                     �    F�      �       
    vM      h                             3                     L                     b    �A      m       }    sQ      �      �    GF      5       �                     �    <x      �      �    �O      �      �    � !            �    {                  !                                  /                     C    �(             T    ` !            h    ��      �       �                     |                      �                     �    !             �    0 !            �                     �    g=      _      �    ��             �    �U      4"      	    <�      �       "	                     9	    �7      �      C	                     W	    +=      <       q	    >~      �       �	    Q      Z       �	    � !            �	     !            �	    �      e       �	    �      C      �	                     
                     
    �M      �       4
                     F
    �D      \       _
                     z
                     �
    S�      (       �
    `S      U       �
                     /    � !             �
    {�      �                 +       �
    
C      �       �
                         �N      �       &    �)      6      ?    � !            N    �I      ^      b    P !             n    �K      �       �    C@      h      ~    	:            �    �D             �    �T             �                     �                     �                     �                     �                          ��      �                            ,                     C                     V                     j    R�      1      �                     �    T      h       �    �T      �       �    ��      �      �                     �                                               m      _           \4      �      3                     K    ��            f    �S      f       }    |F      ~      �    I      �       �    �J      =       �                     �                     �   P !             �    �0            �                      
          �           E      ?      [    $ !            6    ��      �      O    N�      N      d                     }                     �                     �  "                   �    �              �    ��            �    IL      D       �    F%      9      �    � !                                                      4    I             C    � !            W    �N             g                      crtstuff.c deregister_tm_clones __do_global_dtors_aux completed.7698 __do_global_dtors_aux_fini_array_entry frame_dummy __frame_dummy_init_array_entry signal_handler.c accept.c is_list_empty cmdline.c help_flag version_flag long_options common.c list_add_tail log.c log_output start_delay log_strings ms_delay main.c stlink_api.c list_del sock_info.c stlink_connection.c stlink_tcp_cmd.c w_4_uint8_to_buf stlink_mgt.c stlink_mgt_init_buffer libusb_mgt.c list_add list_move libusb_get_string_descriptor a_libusb_context stlink_match __FRAME_END__ __init_array_end _DYNAMIC __init_array_start __GNU_EH_FRAME_HDR _GLOBAL_OFFSET_TABLE_ get_stlink_by_serial_name __libc_csu_fini log_init free@@GLIBC_2.2.5 recv@@GLIBC_2.2.5 stlink_usb_blink_led stlink_mgt_close_usb stlink_init stlink_mgt_read_trace_data stlink_usb_list auto_exit_flag __errno_location@@GLIBC_2.2.5 libusb_open strncpy@@GLIBC_2.2.5 strncmp@@GLIBC_2.2.5 _ITM_deregisterTMCloneTable strcpy@@GLIBC_2.2.5 exit_server print_address_string sock_info_keys hotplug_handle sigaction@@GLIBC_2.2.5 setsockopt@@GLIBC_2.2.5 debug_level get_tcp_number_client _edata print_version process_read_event install_ctrl_handler non_blocking_accept_main delete_stlink_from_list strlen@@GLIBC_2.2.5 libusb_release_interface __stack_chk_fail@@GLIBC_2.4 libusb_get_version getopt_long@@GLIBC_2.2.5 htons@@GLIBC_2.2.5 send@@GLIBC_2.2.5 log_print libusb_close is_item_exist_in_stlink_list destroy_listening_sockets gettimeofday@@GLIBC_2.2.5 fputs@@GLIBC_2.2.5 init_sockinfo libusb_get_string_descriptor_ascii memset@@GLIBC_2.2.5 libusb_mgt_refresh libusb_free_config_descriptor ioctl@@GLIBC_2.2.5 stlk_pids delete_sock_info_from_list get_nb_tcp_client libusb_get_config_descriptor close@@GLIBC_2.2.5 hotplug_callback getnameinfo@@GLIBC_2.2.5 libusb_mgt_remove_device get_usb_number_client fputc@@GLIBC_2.2.5 libusb_get_configuration strtok_r@@GLIBC_2.2.5 jenkins_one_at_a_time_hash close_connection stlink_get_device_info2 __libc_start_main@@GLIBC_2.2.5 stlink_mgt_send_cmd add_connection ask_to_kill stlink_mgt_get_version __data_start inet_addr@@GLIBC_2.2.5 signal@@GLIBC_2.2.5 close_socket_env optarg@@GLIBC_2.2.5 libusb_mgt_init_lib __gmon_start__ libusb_hotplug_deregister_callback __dso_handle assoc_list memcpy@@GLIBC_2.14 get_version_cmd _IO_stdin_used process_stlink_tcp_cmd compute_serial_str libusb_get_device_list send_data select@@GLIBC_2.2.5 handle_log_output_command stlink_mgt_get_current_mode evaluate_auto_kill g_listening_sock_nb connection_list __libc_csu_init stlink_mgt_exit_jtag_mode malloc@@GLIBC_2.2.5 fflush@@GLIBC_2.2.5 stlink_connection_invalid_usb libusb_error_name get_stlink_by_list_index __isoc99_sscanf@@GLIBC_2.7 libusb_bulk_transfer libusb_mgt_exit_lib get_connection_by_name listen@@GLIBC_2.2.5 libusb_mgt_set_configuration get_stlink_by_key libusb_set_configuration make_connection create_listening_sockets accept_context stlink_send_command __bss_start alloc_sock_info log_out stlink_get_nb_devices free_token bind@@GLIBC_2.2.5 libusb_get_device libusb_exit libusb_init libusb_get_device_descriptor stlink_mgt_dfu_exit libusb_free_device_list libusb_claim_interface fopen@@GLIBC_2.2.5 strtok@@GLIBC_2.2.5 libusb_mgt_claim_interface vfprintf@@GLIBC_2.2.5 get_nb_client_for_usb error_convert libusb_mgt_init_refresh accept@@GLIBC_2.2.5 strtoul@@GLIBC_2.2.5 atoi@@GLIBC_2.2.5 nth_sock get_stlink_tcp_cmd_data libusb_control_transfer stlink_mgt_open_usb_dbg_if get_connection_by_sock stlink_open_device stlink_close list_count sprintf@@GLIBC_2.2.5 exit@@GLIBC_2.2.5 __TMC_END__ process_accept_event _ITM_registerTMCloneTable stlink_mgt_jtag_exit stlink_get_device_info libusb_mgt_bulk_transfer libusb_mgt_real_open getaddrinfo@@GLIBC_2.2.5 strdup@@GLIBC_2.2.5 strerror@@GLIBC_2.2.5 __cxa_finalize@@GLIBC_2.2.5 stlink_mgt_exit_dfu_mode free_sock_info parse_params g_rwMiscOwner usleep@@GLIBC_2.2.5 freeaddrinfo@@GLIBC_2.2.5 stlink_refresh stderr@@GLIBC_2.2.5 new_assoc_index socket@@GLIBC_2.2.5  .symtab .strtab .shstrtab .interp .note.ABI-tag .note.gnu.build-id .gnu.hash .dynsym .dynstr .gnu.version .gnu.version_r .rela.dyn .rela.plt .init .plt.got .text .fini .rodata .eh_frame_hdr .eh_frame .init_array .fini_array .data.rel.ro .dynamic .data .bss .comment .debug_aranges .debug_info .debug_abbrev .debug_line .debug_str .debug_ranges                                                                                  8      8                                    #             T      T                                     1             t      t      $                              D   ���o       �      �      @                             N             �      �      �                          V             X
      X
      /                             ^   ���o       �      �      �                            k   ���o       (      (      p                            z             �      �      �                           �      B       h      h      H                          �             �      �                                    �             �      �      @                            �                                                      �                           b�                             �             ��      ��      	                              �             ��      ��      �1                             �              �       �                                   �             @�      @�      �                             �             P�      P�                                   �             X�      X�                                   �             `�      `�                                    �             p�      p�                                  �             ��      ��      X                            �               !            P                              �             ` !     P      �                                    0               P      )                                                  y      @                                                  �     O�                             &                     �     �                             4                     �     S,                             @     0               X�     3"                            K                     �     p                                                          �      "   V                 	                      �+     {                                                   ;     Y                                                                                                                                                                                     ./cleanup.sh                                                                                        0000755 0117457 0127674 00000000526 14436403737 012464  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 #!/bin/bash

thisdir=$(readlink -m $(dirname $0))

cd $thisdir

# Selective cleanup as self extract may have been
# done in a user-created dir.

# Remove known objects
for item in $(cat pkg_rootdir_content.txt) root
do
        rm -rf $item
done

# Attempt to remove dir only if it's empty
if [ -z "$(ls -A)" ]; then
        rmdir $thisdir
fi
                                                                                                                                                                          ./pkg_rootdir_content.txt                                                                           0000644 0117457 0127674 00000000122 14436403737 015304  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 cleanup.sh
pkg_rootdir_content.txt
prompt_linux_license.sh
setup.sh
stlink-server
                                                                                                                                                                                                                                                                                                                                                                                                                                              ./prompt_linux_license.sh                                                                           0000644 0117457 0127674 00000020743 14436403737 015277  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 #!/bin/bash

if [ "$LICENSE_ALREADY_ACCEPTED" ] ; then
	exit 0
fi

display_license() {
cat << EOF
STMicroelectronics Software License Agreement

SLA0048 Rev4/March 2018

Please indicate your acceptance or NON-acceptance by selecting "I ACCEPT" or "I DO NOT ACCEPT" as indicated below in the media.

BY INSTALLING COPYING, DOWNLOADING, ACCESSING OR OTHERWISE USING THIS SOFTWARE PACKAGE OR ANY PART THEREOF (AND THE RELATED DOCUMENTATION) FROM STMICROELECTRONICS INTERNATIONAL N.V, SWISS BRANCH AND/OR ITS AFFILIATED COMPANIES (STMICROELECTRONICS), THE RECIPIENT, ON BEHALF OF HIMSELF OR HERSELF, OR ON BEHALF OF ANY ENTITY BY WHICH SUCH RECIPIENT IS EMPLOYED AND/OR ENGAGED AGREES TO BE BOUND BY THIS SOFTWARE PACKAGE LICENSE AGREEMENT.

Under STMicroelectronics' intellectual property rights and subject to applicable licensing terms for any third-party software incorporated in this software package and applicable Open Source Terms (as defined here below), the redistribution, reproduction and use in source and binary forms of the software package or any part thereof, with or without modification, are permitted provided that the following conditions are met:
1. Redistribution of source code (modified or not) must retain any copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form, except as embedded into microcontroller or microprocessor device manufactured by or for STMicroelectronics or a software update for such device, must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of STMicroelectronics nor the names of other contributors to this software package may be used to endorse or promote products derived from this software package or part thereof without specific written permission.
4. This software package or any part thereof, including modifications and/or derivative works of this software package, must be used and execute solely and exclusively on or in combination with a microcontroller or a microprocessor devices manufactured by or for STMicroelectronics.
5. No use, reproduction or redistribution of this software package partially or totally may be done in any manner that would subject this software package to any Open Source Terms (as defined below).
6. Some portion of the software package may contain software subject to Open Source Terms (as defined below) applicable for each such portion ("Open Source Software"), as further specified in the software package. Such Open Source Software is supplied under the applicable Open Source Terms and is not subject to the terms and conditions of license hereunder. "Open Source Terms" shall mean any open source license which requires as part of distribution of software that the source code of such software is distributed therewith or otherwise made available, or open source license that substantially complies with the Open Source definition specified at www.opensource.org and any other comparable open source license such as for example GNU General Public License (GPL), Eclipse Public License (EPL), Apache Software License, BSD license and MIT license.
7. This software package may also include third party software as expressly specified in the software package subject to specific license terms from such third parties. Such third party software is supplied under such specific license terms and is not subject to the terms and conditions of license hereunder. By installing copying, downloading, accessing or otherwise using this software package, the recipient agrees to be bound by such license terms with regard to such third party software.
8. STMicroelectronics has no obligation to provide any maintenance, support or updates for the software package.
9. The software package is and will remain the exclusive property of STMicroelectronics and its licensors. The recipient will not take any action that jeopardizes STMicroelectronics and its licensors' proprietary rights or acquire any rights in the software package, except the limited rights specified hereunder.
10. The recipient shall comply with all applicable laws and regulations affecting the use of the software package or any part thereof including any applicable export control law or regulation.
11. Redistribution and use of this software package partially or any part thereof other than as permitted under this license is void and will automatically terminate your rights under this license.

THIS SOFTWARE PACKAGE IS PROVIDED BY STMICROELECTRONICS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS, IMPLIED OR STATUTORY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT OF THIRD PARTY INTELLECTUAL PROPERTY RIGHTS ARE DISCLAIMED TO THE FULLEST EXTENT PERMITTED BY LAW. IN NO EVENT SHALL STMICROELECTRONICS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EXCEPT AS EXPRESSLY PERMITTED HEREUNDER AND SUBJECT TO THE APPLICABLE LICENSING TERMS FOR ANY THIRD-PARTY SOFTWARE INCORPORATED IN THE SOFTWARE PACKAGE AND OPEN SOURCE TERMS AS APPLICABLE, NO LICENSE OR OTHER RIGHTS, WHETHER EXPRESS OR IMPLIED, ARE GRANTED UNDER ANY PATENT OR OTHER INTELLECTUAL PROPERTY RIGHTS OF STMICROELECTRONICS OR ANY THIRD PARTY.
EOF
}

# Make sure we use bash (#! may be overriden by caller script)
if [ "$(ps -o comm h -p $$)" != 'bash' ]
then
	exec /bin/bash "$0" "$@"
fi

export -f display_license

# Prompt user for license acceptance.
# Depending on options and environment, choose proper display tool.
# As terminal mode may not be detected when run from a script,
#   --force-console is here for automation purpose when testing. (ie. using expect)

set -e

box_title="STM32CubeIDE - License Agreement"

terminal_prompt() {
	rc_file=$1
	local rc

	typeset -l answer
	display_license | more
	echo
	read -p "I ACCEPT (y) / I DO NOT ACCEPT (N) [N/y] " answer
	if [ "$answer" = "y" ]; then
		# License accepted
		rc=0
		echo "License accepted."
	else
		# License not accepted
		rc=1
		echo "*** License NOT accepted. Not installing software. Hit return to exit."
		read
	fi

	# If exit code cannot be captured by caller, use this temp file
	if [ "$rc_file" ]
	then
		echo $rc > $rc_file
	fi

	exit $rc
}
export -f terminal_prompt

# Special treatment for RPM
if [[ ${BASH_SOURCE[0]} =~ '/var/tmp/rpm-tmp.' ]]; then
	if [ "$INTERACTIVE" = FALSE ] ; then
		# If not interactive and DISPLAY is not set (X11 installer seems to not propagate this variable)
		# then force it to :0
		export DISPLAY=${DISPLAY:-:0}
		# If this fails, then installation fails and user does not know it but what else can we do?
	else
		# Restore stdin as rpm installer closes it before running scriptlets.
		exec 0</dev/tty
	fi
fi

if [ -t 0 -o "$STM_FORCE_CONSOLE" ]
then
	# Terminal detected or wanted
	terminal_prompt

	# Unreached
	echo >&2 "Bug in $0 (terminal_prompt)"
	exit 3
fi

# No terminal
if [ -z "$DISPLAY" ]
then
	echo >&2 "DISPLAY not set. Cannot display license. Aborting."
	exit 2
fi


# Find first available X11 tool
dialog_tools="zenity xterm"
for tool in $dialog_tools
do
	if ( type >/dev/null -f $tool )
	then
		dialog=$tool
		break
	fi
done

case $dialog in
xterm)
	# Use terminal mode in an xterm

	# Workaround as xterm does not return "-e command" exit code
	exit_code_tmp_file=$(mktemp)
	xterm -title "$box_title" -ls -geometry 115x40 -sb -sl 1000 -e "terminal_prompt $exit_code_tmp_file"
	rc=$(cat $exit_code_tmp_file)
	rm $exit_code_tmp_file
	exit $rc
	;;
zenity)
	# Little trick below as default button of zenity is 'ok' and we want it to be 'cancel'.
	# So just swap buttons labels and use reverse condition for acceptance.
	display_license | zenity \
		--text-info \
		--title="$box_title" \
		--width=650 --height=500 \
		--cancel-label "I ACCEPT" \
		--ok-label "I DO NOT ACCEPT" \
		|| exit 0 # Accepted

	# Not accepted
	zenity \
		--error \
		--title="$box_title" \
		--text "License NOT accepted. Not installing software."
	exit 1
	;;
*)
	echo >&2 "No dialog tool found to display license. Aborting."
	exit 2
esac

# Should be unreached
echo >&2 "No way to display license. Aborting."
exit 3
                             ./setup.sh                                                                                          0000755 0117457 0127674 00000004721 14436403737 012176  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 #!/bin/bash

thisdir=$(readlink -m $(dirname $0))

set -e
err_handler(){
	echo >&2 "Error installing stlink-server"
	exit 1
}

trap err_handler ERR
trap $thisdir/cleanup.sh EXIT

help() {
	echo "$0 usage:"
	echo "$0 [-f]"
	echo "   -f: do not check for downgrade"
}

# Ask user to agree on license
bash $thisdir/prompt_linux_license.sh
if [ $? -ne 0 ]
then
	exit 1
fi


stls_dir=/usr/bin
stls_abs_path=$stls_dir/stlink-server

# Arguments check
downgrade_check=1

case "$1" in
'')
	;;
-f)
	downgrade_check=
	;;
-h)
	help
	exit 0
	;;
*)
	help
	exit 1
	;;
esac

# Get version to be installed
set junk  $(./stlink-server 2>&1 -v)
tobe_installed_version_string=$3
# Below, strip off potential git describe string and 'v' prefix
tobe_installed_version=$(echo ${3%%-g*}|sed 's/^v//')
tobe_installed_timestamp=$4

echo "stlink-server $tobe_installed_version_string $tobe_installed_timestamp installation started."

if [ "$downgrade_check" -a -x $stls_abspath ] ; then
	# Check we do not downgrade already installed stlink-server
	downgrade_attempt=

	# Get already installed stlink-server version
	set junk  $($stls_abs_path 2>&1 -v)
	installed_version_string=$3
	# Below, strip off potential git describe string and 'v' prefix
	installed_version=$(echo ${3%%-g*}|sed 's/^v//')
	installed_timestamp=$4

	if [ "$installed_version" = "$tobe_installed_version" ]; then
		# If versions are the same then rely on timestamp
		newest_timestamp=$(
			(
				echo $installed_timestamp
				echo $tobe_installed_timestamp
			) |sort|tail -1
		)
		if [ "$newest_timestamp" = "$installed_timestamp" ]; then
			downgrade_attempt=yes
		fi
	else
		# Compare versions (without v prefix) sort -V (version-sort) not present on all linux so use sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n
		newest_version=$(
			(
				echo $installed_version
				echo $tobe_installed_version
			) |sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n|tail -1
		)
		if [ "$newest_version" = "$installed_version" ]; then
			downgrade_attempt=yes
		fi
	fi

	if [ "$downgrade_attempt" ]; then
		echo "Already installed version is newer or equal: $installed_version_string $installed_timestamp"
		echo "NOT downgrading. Aborting stlink-server installation."

		# This is not considered as a failure. Global installation must continue.
		exit 0
	fi

fi

# Finally, perform installation
echo "Stopping stlink-server (if any)..."
killall stlink-server -q || true
cp stlink-server $stls_dir
chmod 0755 $stls_abs_path
chown root:root $stls_abs_path

echo "Installation done."
exit 0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               