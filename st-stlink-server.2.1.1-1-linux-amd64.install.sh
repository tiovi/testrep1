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
./                                                                                                  0000700 0117457 0127674 00000000000 14436403737 010461  5                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 ./stlink-server                                                                                     0000755 0117457 0127674 00000442550 14436403737 013243  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 ELF          >           @       h<         @ 8 	 @ $ #       @       @       @       ø      ø                   8      8      8                                                         Ğê      Ğê                    Pú      Pú      Pú                                 pû      pû      pû                                 T      T      T      D       D              Påtd    Û       Û       Û                         Qåtd                                                  Råtd   Pú      Pú      Pú      °      °             /lib64/ld-linux-x86-64.so.2          GNU                        GNU ş^Ñ
Ÿ‹1öB}‰#ñÙ¡   I         ˆÅ  DI   K   N   BEÕì»ã’|ØqX¸ñ9ò‹êÓï³¢÷                        Ç                     5                     :                     <                     ®                                                                 t                                          R                     <                     ã                     V                      ¶                     l                     b                     {                     0                     À                     ¥                      u                                                               ö                                          \                     ä                      ¬                                                                Œ                      $                     ¬                                          §                     ¿                     -                       ®                     -                     Í                      Î                     G                     m                     H                     —                     ¸                      Ç                     İ                     ı                     Z                     ö                     Ñ                     o                                                                ‰                     Ü                     ¾                     K                     4                     ‚                     –                                          ı                     <                       ê                     Õ                     £                     ‡  "                   n                     –                     f                     Ì    P !             ß    à !             Ó    P !             ×    °              U    € !            ²     „©              N    ` !             libusb-1.0.so.0 _ITM_deregisterTMCloneTable __gmon_start__ _ITM_registerTMCloneTable libusb_release_interface libusb_get_device_descriptor libusb_get_configuration libusb_close _fini libusb_bulk_transfer libusb_get_device_list libusb_get_config_descriptor libusb_free_device_list libusb_get_string_descriptor_ascii libusb_open libusb_error_name libusb_get_device libusb_get_version libusb_claim_interface libusb_control_transfer libusb_hotplug_deregister_callback libusb_init libusb_set_configuration libusb_exit libusb_free_config_descriptor libpthread.so.0 send recv __errno_location accept sigaction libc.so.6 socket fflush strcpy htons sprintf fopen strncmp __isoc99_sscanf signal strncpy __stack_chk_fail listen select strdup strtok strlen getaddrinfo memset bind getnameinfo fputc inet_addr fputs strtok_r memcpy strtoul setsockopt malloc optarg stderr ioctl getopt_long usleep gettimeofday atoi __cxa_finalize freeaddrinfo strerror __libc_start_main vfprintf free _edata __bss_start _end GLIBC_2.2.5 GLIBC_2.7 GLIBC_2.14 GLIBC_2.4 /src/staging/libusb/linux64/lib                                                                                                                      ui	   ä        \         ii   ğ     ”‘–   ú     ii        ui	   ä      Pú                    Xú             à      `ú             0«      pú             Œ !     €ú             5«      ú              !      ú             =«      Àú             C«      àú             H«       û             R«      @û             Mµ      Hû             Uµ      Pû             ]µ      Xû             eµ      `û             mµ      hû             uµ       !             !      !             !      !             !     0 !            0 !     8 !            0 !     @ !            @ !     H !            @ !     Àÿ                    Èÿ         !           Ğÿ         %           Øÿ         A           àÿ         E           ` !        O           € !        M           ¨ı                    °ı                    ¸ı                    Àı                    Èı                    Ğı                    Øı                    àı         	           èı         
           ğı                    øı                     ş                    ş                    ş                    ş                     ş                    (ş                    0ş                    8ş                    @ş                    Hş                    Pş                    Xş                    `ş                    hş                    pş                    xş                    €ş                    ˆş                    ş                    ˜ş                      ş         "           ¨ş         #           °ş         $           ¸ş         &           Àş         '           Èş         (           Ğş         )           Øş         *           àş         +           èş         ,           ğş         -           øş         .            ÿ         /           ÿ         0           ÿ         1           ÿ         2            ÿ         3           (ÿ         4           0ÿ         5           8ÿ         6           @ÿ         7           Hÿ         8           Pÿ         9           Xÿ         :           `ÿ         ;           hÿ         <           pÿ         =           xÿ         >           €ÿ         ?           ˆÿ         @           ÿ         B           ˜ÿ         C            ÿ         D           ¨ÿ         F           °ÿ         G           ¸ÿ         H           HƒìH‹ç  H…ÀtÿĞHƒÄÃ         ÿ5Âä  ÿ%Ää  @ ÿ%Âä  h    éàÿÿÿÿ%ºä  h   éĞÿÿÿÿ%²ä  h   éÀÿÿÿÿ%ªä  h   é°ÿÿÿÿ%¢ä  h   é ÿÿÿÿ%šä  h   éÿÿÿÿ%’ä  h   é€ÿÿÿÿ%Šä  h   épÿÿÿÿ%‚ä  h   é`ÿÿÿÿ%zä  h	   éPÿÿÿÿ%rä  h
   é@ÿÿÿÿ%jä  h   é0ÿÿÿÿ%bä  h   é ÿÿÿÿ%Zä  h   éÿÿÿÿ%Rä  h   é ÿÿÿÿ%Jä  h   éğşÿÿÿ%Bä  h   éàşÿÿÿ%:ä  h   éĞşÿÿÿ%2ä  h   éÀşÿÿÿ%*ä  h   é°şÿÿÿ%"ä  h   é şÿÿÿ%ä  h   éşÿÿÿ%ä  h   é€şÿÿÿ%
ä  h   épşÿÿÿ%ä  h   é`şÿÿÿ%úã  h   éPşÿÿÿ%òã  h   é@şÿÿÿ%êã  h   é0şÿÿÿ%âã  h   é şÿÿÿ%Úã  h   éşÿÿÿ%Òã  h   é şÿÿÿ%Êã  h   éğıÿÿÿ%Âã  h    éàıÿÿÿ%ºã  h!   éĞıÿÿÿ%²ã  h"   éÀıÿÿÿ%ªã  h#   é°ıÿÿÿ%¢ã  h$   é ıÿÿÿ%šã  h%   éıÿÿÿ%’ã  h&   é€ıÿÿÿ%Šã  h'   épıÿÿÿ%‚ã  h(   é`ıÿÿÿ%zã  h)   éPıÿÿÿ%rã  h*   é@ıÿÿÿ%jã  h+   é0ıÿÿÿ%bã  h,   é ıÿÿÿ%Zã  h-   éıÿÿÿ%Rã  h.   é ıÿÿÿ%Jã  h/   éğüÿÿÿ%Bã  h0   éàüÿÿÿ%:ã  h1   éĞüÿÿÿ%2ã  h2   éÀüÿÿÿ%*ã  h3   é°üÿÿÿ%"ã  h4   é üÿÿÿ%ã  h5   éüÿÿÿ%ã  h6   é€üÿÿÿ%
ã  h7   épüÿÿÿ%ã  h8   é`üÿÿÿ%úâ  h9   éPüÿÿÿ%òâ  h:   é@üÿÿÿ%êâ  h;   é0üÿÿÿ%ââ  h<   é üÿÿÿ%Úâ  h=   éüÿÿÿ%Òâ  h>   é üÿÿÿ%Êâ  h?   éğûÿÿÿ%Ââ  h@   éàûÿÿÿ%ºâ  hA   éĞûÿÿÿ%²â  hB   éÀûÿÿÿ%Êâ  f        1íI‰Ñ^H‰âHƒäğPTLJŒ  HÓ‹  H=ÿ"  ÿ~â  ôD  H=ùâ  UHñâ  H9øH‰åtH‹Râ  H…Àt]ÿàf.„     ]Ã@ f.„     H=¹â  H5²â  UH)şH‰åHÁşH‰ğHÁè?HÆHÑştH‹â  H…Àt]ÿàf„     ]Ã@ f.„     €=¡â   u/Hƒ=ïá   UH‰åtH‹=
â  èÿÿÿèHÿÿÿÆyâ  ]Ã€    óÃfD  UH‰å]éfÿÿÿUH‰åHƒì ‰}üH‰uğH‰Uè‹Eü‰ÂH5O‹  ¿   ¸    è¹  ‹Eüƒøtë H=?‹  èâúÿÿèZ  èL
  ‹Eü‰ÇèşÿÿÉÃUH‰åHì°   dH‹%(   H‰Eø1ÀH…`ÿÿÿº˜   ¾    H‰Çè‰ûÿÿHlÿÿÿH‰…`ÿÿÿÇEè   H…`ÿÿÿº    H‰Æ¿   è{úÿÿ‰…\ÿÿÿƒ½\ÿÿÿ y%‹…\ÿÿÿ‰ÂH5µŠ  ¿    ¸    èÿ  ¸    ë&‹á  ƒø~H5µŠ  ¿   ¸    è×  ¸   H‹MødH3%(   tèMúÿÿÉÃUH‰åH‰}øH‹EøH‹ H9Eø”À]ÃUH‰å‰}ÜHÇEè    H‹à  H‰Eàë/H‹EàH‰EğH‹EğH‰Eø‹EÜH9EèuH‹Eøë"HƒEèH‹EàH‹ H‰EàHQà  H9EàuÄ¸    ]ÃUH‰å‹Jà  ƒø~H5&Š  ¿   ¸    è   è×  èÉ  èS‚  ¿   è–üÿÿUH‰åHì   dH‹%(   H‰Eø1ÀHÇ…0ÿÿÿ   Ç…ÿÿÿ    Ç…ÿÿÿ    ‹×ß  ƒøÆ  H5¿‰  ¿   ¸    è©  é«  ƒ…ÿÿÿÆ…ÿÿÿ ¸    ¹   H•pÿÿÿH‰×üóH«‰ø‰Ê‰• ÿÿÿ‰…$ÿÿÿÇ…ÿÿÿ    H‹[ß  H‰…(ÿÿÿé‰   H‹…(ÿÿÿH‰…PÿÿÿH‹…PÿÿÿH‰…XÿÿÿH‹…Xÿÿÿ‹@P?…ÀHÂÁø‰ÆHcÆH‹¼ÅpÿÿÿH‹…Xÿÿÿ‹@™ÁêĞƒà?)Ğº   ‰ÁHÓâH‰ĞH	ÇH‰úHcÆH‰”Åpÿÿÿƒ…ÿÿÿH‹…(ÿÿÿH‹ H‰…(ÿÿÿH¿Ş  H9…(ÿÿÿ…cÿÿÿ¶$ß  „Àt6‹%ß  9…ÿÿÿ(‹£Ş  ƒø~H5±ˆ  ¿   ¸    èy  Æ…ÿÿÿH‹…0ÿÿÿH‰…`ÿÿÿHÇ…hÿÿÿ    H•`ÿÿÿH…pÿÿÿI‰Ğ¹    º    H‰Æ¿   èPùÿÿ‰…ÿÿÿƒ½ÿÿÿ ‰‰   è÷ÿÿ‹ ‰…ÿÿÿƒ½ÿÿÿt ‹…ÿÿÿ‰ÂH54ˆ  ¿    ¸    èê  ë)‹ñİ  ƒø~‹…ÿÿÿ‰ÂH5%ˆ  ¿   ¸    è¿  €½ÿÿÿ tèlıÿÿƒ½ÿÿÿ„«  ¿ÀÆ- èiúÿÿéœ  ƒ½ÿÿÿ uB‹•İ  ƒø~ H‹…0ÿÿÿH‰ÂH5ï‡  ¿   ¸    èa  €½ÿÿÿ „[  è
ıÿÿéQ  €½ÿÿÿ t(‹Jİ  ƒø~H5Û‡  ¿   ¸    è   Æ‘İ   H‹İ  H‰…(ÿÿÿéù  H‹…(ÿÿÿH‰…8ÿÿÿH‹…8ÿÿÿH‰…@ÿÿÿƒ½ÿÿÿ ¿  H‹…@ÿÿÿ‹@P?…ÀHÂÁøH˜H‹´ÅpÿÿÿH‹…@ÿÿÿ‹@™ÁêĞƒà?)Ğº   ‰ÁHÓâH‰ĞH!ğH…À„r  ƒ­ÿÿÿH‹…@ÿÿÿ¶@„Àt1‹ƒÜ  ƒø~&H‹…@ÿÿÿ¶@¶À‰ÂH5‡  ¿   ¸    èI  H‹…@ÿÿÿ¶@„ÀtUH‹…@ÿÿÿH‰Çè  H…À…  €½ÿÿÿ „÷   ‹Ü  ƒø~H5Ú†  ¿   ¸    èô  ¿    èò,  éÇ   H‹…@ÿÿÿH‰ÇèÄ  ˆ…ÿÿÿ¶…ÿÿÿƒğ„ÀtH‹…@ÿÿÿH‰Çè†  ˆ…ÿÿÿéŠ   H‹…@ÿÿÿ‹@‰ÇèöÿÿH‹…@ÿÿÿH‰Çè,/  H‰…HÿÿÿHƒ½Hÿÿÿ tH‹…Hÿÿÿ‹@$‰Çèh$  ë
¿    èb,  ‹cÛ  ƒø~HGÛ  H5H†  ¿   ¸    è2  H‹…@ÿÿÿH‰ÇèŸ'  é{ûÿÿH‹…(ÿÿÿH‹ H‰…(ÿÿÿHÛ  H9…(ÿÿÿ…óıÿÿH=ñÚ  è1úÿÿƒğ„À…>ûÿÿH‹EødH3%(   tè\ôÿÿÉÃUH‰åHƒì ‰}ìH‰uàdH‹%(   H‰Eø1ÀÇEğ    HUğH‹uà‹EìI‰ĞHàÔ  HÖ…  ‰Çè2ôÿÿ‰Eôƒ}ôÿu‹ïÚ  …À…  é¡  ‹pÚ  ƒø~‹Eô‰ÂH5§…  ¿   ¸    èA  ‹Eôƒøht2ƒøhƒøatFƒødtn…Àé´  ƒøp„D  ƒøvtƒøl„¿   é˜  ÇxÚ     é‰  ÇmÚ     éz  ‹òÙ  ƒø~H5?…  ¿   ¸    èÈ  Æ`Ú  éM  ‹ÅÙ  ƒø~5H‹ùÙ  H…Àt	H‹íÙ  ëH
…  H‰ÂH5…  ¿   ¸    è|  H‹ÄÙ  H…Àt	H‹¸Ù  ëHÕ„  H‰Çè·õÿÿ‰aÙ  éŞ   ‹VÙ  ƒø~ H‹ŠÙ  H‰ÂH5º„  ¿   ¸    è"  H‹jÙ  H…À„¢   ‹Ù  ƒø~ H‹OÙ  H‰ÂH5„  ¿   ¸    èç  H‹/Ù  H‰Çèò  ëf‹ßØ  ƒø~5H‹Ù  H…Àt	H‹Ù  ëHY„  H‰ÂH5T„  ¿   ¸    è–  H‹ŞØ  H…Àt	H‹ÒØ  ëH$„  H‰Çè,  ëé½ıÿÿH5„  ¿ÿÿÿÿ¸    èL  H5„  ¿ÿÿÿÿ¸    è6  H5.„  ¿ÿÿÿÿ¸    è   H5H„  ¿ÿÿÿÿ¸    è
  H5b„  ¿ÿÿÿÿ¸    èô  H5¼„  ¿ÿÿÿÿ¸    èŞ  H5Ş„  ¿ÿÿÿÿ¸    èÈ  ¿ÿÿÿÿèUôÿÿ‹?Ø  …Àtèl  ¿    è<ôÿÿ¸    H‹MødH3%(   tè#ñÿÿÉÃUH‰åH‰}øH‰uğH‹EøH‹UğH‰H‹EğH‹PH‹EøH‰PH‹EğH‹@H‹UøH‰H‹EğH‹UøH‰P]ÃUH‰å]ÃUH‰åHƒìH‰}øH‹EøH‰ÇèİóÿÿH‰æ×  ÉÃUH‰åHƒì`H‰}¨H‰u dH‹%(   H‰Eø1ÀH‹E ‰ÆHUÀH‹E¨HƒìjA¹    A¸    ¹.   H‰ÇèWñÿÿHƒÄ‰E¼ƒ}¼ t‹E¼‰ÂH5öƒ  ¿   ¸    è°  ëHEÀH‰ÂH5„  ¿   ¸    è‘  H‹EødH3%(   tèğÿÿÉÃUH‰åHì   dH‹%(   H‰Eø1ÀHÇE˜   Æ…uÿÿÿ ÇE„    ÇÃÖ      ‹IÖ  ƒø~H5­ƒ  ¿   ¸    è  ‹(Ö  ƒø~H5´ƒ  ¿   ¸    èş  HE°º0   ¾    H‰ÇèğÿÿÇE´   ÇE¼   ÇE¸   ÇE°   ‹ÕÕ  ƒø~*H‹yÖ  H‹jÖ  H‰ÑH‰ÂH5|ƒ  ¿   ¸    è—  H‹OÖ  H‰ÂH5zƒ  ¿   ¸    èw  H‹/Ö  HMHU°H‰Æ¿    èúñÿÿ…Àt*èAîÿÿ‹ ‰E„‹E„‰ÂH5Hƒ  ¿    ¸    è2  éu  H‹EH…ÀuH5Dƒ  ¿    ¸    è  éQ  ‹Õ  ƒø~H5>ƒ  ¿   ¸    èè  H‹EH‰E ÇE€   é  ‹İÔ  ƒø~-H‹E H‹H ‹U€H‹E I‰È‰ÑH‰ÂH52ƒ  ¿   ¸    èœ  H‹E ‹PH‹E ‹HH‹E ‹@‰Î‰Çèmñÿÿ‰Eˆƒ}ˆÿu@è_íÿÿ‹ ‰E„‹E„‰ÂH5ƒ  ¿    ¸    èP  H5(ƒ  ¿    ¸    è:  éa  ‹>Ô  ƒø~‹Eˆ‰ÂH55ƒ  ¿   ¸    è  H‹ÇÔ  H‰Çè_ğÿÿf‰…vÿÿÿfÇEà ·…vÿÿÿ‰Çè¤íÿÿf‰EâH=ƒ  è”îÿÿ‰EäHEà¾   H‰ÇèüÿÿÇ…xÿÿÿ   H•xÿÿÿ‹EˆA¸   H‰Ñº   ¾   ‰Çèòìÿÿ‰EŒƒ}Œÿu-ètìÿÿ‹ ‰E„‹E„‰Çè5ğÿÿH‰ÂH5³‚  ¿    ¸    è]  Ç…|ÿÿÿ À  H•|ÿÿÿ‹EˆA¸   H‰Ñº   ¾   ‰Çèìÿÿ‰EŒƒ}Œÿu-èìÿÿ‹ ‰E„‹E„‰ÇèÑïÿÿH‰ÂH5‚  ¿    ¸    èù  H•|ÿÿÿ‹EˆA¸   H‰Ñº   ¾   ‰Çè4ìÿÿ‰EŒƒ}Œÿu-è¶ëÿÿ‹ ‰E„‹E„‰ÇèwïÿÿH‰ÂH5U‚  ¿    ¸    èŸ  HEàH‰Á‹Eˆº   H‰Î‰Çè%îÿÿ…ÀtZèlëÿÿ‹ ‰E„ƒ}„buH5B‚  ¿   ¸    è\  ë#‹E„‰ÇèïÿÿH‰ÂH5@‚  ¿    ¸    è7  ‹Eˆ‰ÇèœìÿÿéT  ‹1Ò  ƒø~H5*‚  ¿   ¸    è  ‹Eˆ¾   ‰Çèwíÿÿ…Àt/èŞêÿÿ‹ ‰E„‹E„‰ÆH=‚  ¸    è³ëÿÿ‹Eˆ‰Çè9ìÿÿéñ   ‹ÎÑ  ƒø~H5û  ¿   ¸    è¤  HU˜‹Eˆ¾!T  ‰Ç¸    èÛëÿÿƒøÿu%èqêÿÿ‹ ‰E„‹E„‰ÂH5Ğ  ¿    ¸    èb  èØ  H‰E¨Hƒ}¨ u"H5Ş  ¿    ¸    è<  ‹Eˆ‰Çè¡ëÿÿë\H‹E¨‹Uˆ‰PH‹E¨Æ@H‹E¨H5Ñ  H‰Çèyùÿÿ‹ˆÑ  ƒÀ‰Ñ  Æ…uÿÿÿ‹şĞ  ƒø~H5’  ¿   ¸    èÔ  H‹E H‹@(H‰E ƒE€Hƒ}  …åûÿÿH‹EH…Àt-H‹EH‰Çè‚íÿÿ‹¬Ğ  ƒø~H5p  ¿   ¸    è‚  ‹‹Ğ  ƒø~H5‡  ¿   ¸    èa  ¶…uÿÿÿH‹MødH3%(   tèÕéÿÿÉÃUH‰åHƒì ‹EĞ  ƒø~H5i  ¿   ¸    è  H‹Ğ  H‰EàH‹EàH‹ H‰Eèéœ   H‹EàH‰EğH‹EğH‰Eø‹ùÏ  ƒø~H‹Eø‹@‰ÂH5<  ¿   ¸    èÆ
  H‹Eø‹@ƒøÿtCH‹Eø‹@‰Çèêÿÿ‹µÏ  ƒø~H‹Eø‹@‰ÂH5  ¿   ¸    è‚
  H‹EøÇ@ÿÿÿÿH‹EèH‰EàH‹EàH‹ H‰EèH\Ï  H9Eà…SÿÿÿÇÌÏ      ‹RÏ  ƒø~H5æ€  ¿   ¸    è(
  ÉÃUH‰åHìÀ   H‰½HÿÿÿdH‹%(   H‰Eø1ÀÇ…Tÿÿÿ€   HÇ…hÿÿÿ    HÇ…`ÿÿÿ   Ç…Xÿÿÿ    ‹ãÎ  ƒø~,H‹…Hÿÿÿ‹@H‹•HÿÿÿH‰Ñ‰ÂH5‰€  ¿   ¸    è£	  H…pÿÿÿH‰ÁH‹…Hÿÿÿ‹@H•TÿÿÿH‰Î‰Çè½êÿÿ‰…\ÿÿÿƒ½\ÿÿÿÿu>èYçÿÿ‹ ‰…Xÿÿÿƒ½Xÿÿÿ t‹…Xÿÿÿ‰ÂH5a€  ¿    ¸    è;	  ¸    é	  ‹…TÿÿÿHcĞH…pÿÿÿH‰ÖH‰ÇèòöÿÿH‹…Hÿÿÿ‹@H•`ÿÿÿ¾!T  ‰Ç¸    èCèÿÿƒøÿu+èÙæÿÿ‹ ‰…Xÿÿÿ‹…Xÿÿÿ‰ÂH52~  ¿    ¸    èÄ  è:  H‰…hÿÿÿHƒ½hÿÿÿ u%H5:~  ¿    ¸    è˜  ‹…\ÿÿÿ‰ÇèúçÿÿëZH‹…hÿÿÿ‹•\ÿÿÿ‰PH‹…hÿÿÿÆ@ H‹…hÿÿÿH5_Í  H‰ÇèÆõÿÿ‹aÍ  ƒø~‹…\ÿÿÿ‰ÂH5}  ¿   ¸    è/  H‹…hÿÿÿH‹MødH3%(   tè£æÿÿÉÃUH‰åHƒì H‰}èÆE÷ H‹Eè¶€ €  „Àt!‹üÌ  ƒø~H5P  ¿   ¸    èÒ  H‹EèHƒÀº€  ¾    H‰ÇèçæÿÿH‹EèHpH‹Eè‹@¹    ºÿ  ‰Çèwåÿÿ‰Eøƒ}ø yaèyåÿÿ‹ ‰Eüƒ}üu*‹ˆÌ  ƒø~H5  ¿   ¸    è^  ÆE÷ éš   ƒ}ü t‹Eü‰ÂH5  ¿    ¸    è4  ÆE÷ësƒ}ø uH5  ¿    ¸    è  ÆE÷ëQH‹Eè‹$€  ‹EøÂH‹Eè‰$€  H‹EèÆ€ €  ‹}øH‹EèHˆ€  H‹EèHPH‹EèHpH‹EèA‰øH‰Çèc!  ¶E÷ÉÃUH‰åHìà   H‰½8ÿÿÿ‰µ4ÿÿÿH‰•(ÿÿÿdH‹%(   H‰Eø1ÀÆ…Cÿÿÿ Ç…Hÿÿÿ    Ç…Lÿÿÿ    Ç…Dÿÿÿ    HÇ…`ÿÿÿ    HÇ…hÿÿÿPÃ  éŞ  ¸    ¹   H•pÿÿÿH‰×üóH«‰ø‰Ê‰•Pÿÿÿ‰…TÿÿÿH‹…8ÿÿÿ‹@P?…ÀHÂÁø‰ÆHcÆH‹¼ÅpÿÿÿH‹…8ÿÿÿ‹@™ÁêĞƒà?)Ğº   ‰ÁHÓâH‰ĞH	ÇH‰úHcÆH‰”ÅpÿÿÿH‹…8ÿÿÿ‹@xH•`ÿÿÿH…pÿÿÿI‰Ğ¹    º    H‰Æè¹åÿÿ‰…Xÿÿÿƒ½Xÿÿÿ L  ‹…4ÿÿÿ+…Dÿÿÿ‰ÂH‹…8ÿÿÿ‹@H‹µ(ÿÿÿ¹    ‰Çè;ãÿÿ‰…Lÿÿÿƒ½Lÿÿÿ ‰Ã   è3ãÿÿ‹ ‰…\ÿÿÿÇ…Lÿÿÿ    ƒ½\ÿÿÿt	ƒ½\ÿÿÿu\ƒ½\ÿÿÿu
¿PÃ  èÜæÿÿƒ…Hÿÿÿƒ½Hÿÿÿ  ‹Ê  ƒø~‹…\ÿÿÿ‰ÂH5}  ¿   ¸    èĞ  Æ…Cÿÿÿé[  ƒ½\ÿÿÿ t)‹ÄÉ  ƒø~‹…\ÿÿÿ‰ÂH5}  ¿   ¸    è’  Æ…Cÿÿÿé  ƒ½Lÿÿÿ u"H5}  ¿    ¸    èg  Æ…Cÿÿÿéò   ‹…Lÿÿÿ…Dÿÿÿ‹…LÿÿÿH˜H…(ÿÿÿéÒ   ƒ½Xÿÿÿ uAƒ…Hÿÿÿƒ½Hÿÿÿµ   ‹'É  ƒø~H5}  ¿   ¸    èı  Æ…Cÿÿÿéˆ   èÛáÿÿ‹ ‰…\ÿÿÿƒ½\ÿÿÿuBƒ…Hÿÿÿƒ½Hÿÿÿ~b‹ÔÈ  ƒø~‹…\ÿÿÿ‰ÂH5è|  ¿   ¸    è¢  Æ…Cÿÿÿë0‹¢È  ƒø~‹…\ÿÿÿ‰ÂH5î|  ¿   ¸    èp  Æ…Cÿÿÿ‹…Dÿÿÿ;…4ÿÿÿs¶…Cÿÿÿƒğ„À…ıÿÿ‹…DÿÿÿH‹MødH3%(   tè¾áÿÿÉÃUH‰åHƒì H‰}èÆE÷ H‹Eè¶€ €  ƒğ„ÀuH‹Eè‹€€  …À*‹È  ƒøS  H5‰|  ¿   ¸    èØ  é8  H‹Eè‹€€  HcĞH‹EèHHH‹Eè‹€€  ‰ÀH4H‹Eè‹@¹    ‰Çèjáÿÿ‰Eøƒ}øÿuSè|àÿÿ‹ ‰Eüƒ}üuH5:|  ¿    ¸    èl  ÆE÷ éÈ   ‹Eü‰ÂH5N|  ¿    ¸    èH  ÆE÷é¤   H‹Eè‹€  ‹EøÂH‹Eè‰€  H‹Eè‹€€  +Eø‰ÂH‹Eè‰€  H‹Eè‹€€  …ÀuH‹EèÆ€ €   H‹Eè‹(€  ‹EøÂH‹Eè‰(€  H‹Eè‹€€  …Àt2‹ÖÆ  ƒø~'H‹Eè‹€  ‹Eø‰Ñ‰ÂH5Á{  ¿   ¸    è›  ¶E÷ÉÃUH‰åHƒì0dH‹%(   H‰Eø1ÀHEà¾    H‰Çèlàÿÿ‰EÔƒ}Ô y‹EÔH˜H‰EØë7H‹EàHiğè  H‹MèHºÏ÷Sã¥›Ä H‰ÈH÷êHÁúH‰ÈHÁø?H)ÂH‰ĞHğH‰EØH‹EØH‹}ødH3<%(   tè™ßÿÿÉÃUH‰åHìà   ‰½,ÿÿÿH‰µ ÿÿÿH‰•`ÿÿÿH‰hÿÿÿL‰…pÿÿÿL‰xÿÿÿ„Àt )E€)M)U )]°)eÀ)mĞ)uà)}ğdH‹%(   H‰…Hÿÿÿ1À‹/Æ  ƒÀ‰&Æ  ‹˜Å  9…,ÿÿÿgÇ…0ÿÿÿ   Ç…4ÿÿÿ0   HEH‰…8ÿÿÿH…PÿÿÿH‰…@ÿÿÿƒ½,ÿÿÿÿu2H‹ËÅ  H•0ÿÿÿH‹ ÿÿÿH‰ÎH‰ÇèZáÿÿH‹«Å  H‰Çè[àÿÿëH‹…HÿÿÿdH3%(   tè‘ŞÿÿÉÃUH‰åHìğ   ‰½ÿÿÿH‰µÿÿÿH‰•`ÿÿÿH‰hÿÿÿL‰…pÿÿÿL‰xÿÿÿ„Àt )E€)M)U )]°)eÀ)mĞ)uà)}ğdH‹%(   H‰…Hÿÿÿ1À‹'Å  ƒÀ‰Å  ‹Ä  9…ÿÿÿJ  Ç…0ÿÿÿ   Ç…4ÿÿÿ0   HEH‰…8ÿÿÿH…PÿÿÿH‰…@ÿÿÿ‹QÄ  ƒø“   èŸıÿÿ‰ÂH‹ºÄ  )Â‰Ğ‰…,ÿÿÿ‹²Ä  ‹…ÿÿÿH˜HÅ    H3¿  H‹H‹€Ä  ‹µ,ÿÿÿA‰ğH5Uy  H‰Ç¸    è»ŞÿÿH‹\Ä  H•0ÿÿÿH‹ÿÿÿH‰ÎH‰ÇèëßÿÿH‹<Ä  H‰Æ¿
   è7Şÿÿëjƒ½ÿÿÿ x-‹…ÿÿÿH˜HÅ    Hµ¾  H‹H‹Ä  H‰ÖH‰ÇèİÿÿH‹ğÃ  H•0ÿÿÿH‹ÿÿÿH‰ÎH‰ÇèßÿÿH‹ĞÃ  H‰Æ¿
   èËİÿÿH‹¼Ã  H‰ÇèlŞÿÿëH‹…HÿÿÿdH3%(   tè¢ÜÿÿÉÃUH‰åÇÃ     H‹kÃ  H‰|Ã  è[üÿÿH‰xÃ  ]ÃUH‰åHƒì H‰}èH‹EèH5Fx  H‰ÇèÖŞÿÿH‰EøHƒ}ø tH‹EøH‰8Ã  ¸    ÉÃUH‰åHƒìpH‰}¨H‰u H‰U˜dH‹%(   H‰Eø1ÀH¸v2.1.1-1H‰EïÆE÷ HÇE¸    HÇEÀ    HÇEÈ    HU°HEïH5Íw  H‰ÇèõÜÿÿH‰E¸Hƒ}¸ t!HƒE¸HE°H‰ÂH5§w  ¿    èÍÜÿÿH‰EÀHƒ}À tHE°H‰ÂH5„w  ¿    èªÜÿÿH‰EÈHƒ}È tHU°H‹EÈH5bw  H‰ÇèˆÜÿÿHƒ}¸ „'  Hƒ}À „  Hƒ}È „  H‹E¸º
   ¾    H‰ÇèñİÿÿH‰EĞH‹EÀº
   ¾    H‰Çè×İÿÿH‰EØH‹EÈº
   ¾    H‰Çè½İÿÿH‰Eà‹sÁ  ƒø~-H‹Eà‰ÁH‹EØ‰ÂH‹EĞA‰È‰Ñ‰ÂH5Äv  ¿   ¸    è2üÿÿ¸ÿÿÿÿH9EĞw<¸ÿÿÿÿH9EĞw1¸ÿÿÿÿH9EĞw&H‹E¨H‹UĞH‰H‹E H‹UØH‰H‹E˜H‹UàH‰éˆ   H‹E¨HÇ     H‹E HÇ     H‹E˜HÇ     ‹ÓÀ  ƒø~\H5Wv  ¿   ¸    è©ûÿÿëDH‹E¨HÇ     H‹E HÇ     H‹E˜HÇ     ‹À  ƒø~H5<v  ¿   ¸    èeûÿÿëH‹EødH3%(   tèÜÙÿÿÉÃUH‰åHƒì dH‹%(   H‰Eø1ÀHÇEà    HÇEè    HÇEğ    HUğHMèHEàH‰ÎH‰Çè[ıÿÿH‹MğH‹UèH‹EàH‰ÆH=Öu  ¸    èÄÙÿÿH‹EødH3%(   tè_ÙÿÿÉÃUH‰åHƒì ‰}ìH‰uàÇEü    è¢üÿÿH=Ãu  èaèÿÿ¾   ¿   ègÚÿÿ‹¡¿  ƒø~H5¢u  ¿   ¸    èwúÿÿèåİÿÿƒğ„ÀtH5™u  ¿    ¸    èUúÿÿH‹Uà‹EìH‰Ö‰Çèyäÿÿ‹M¿  ƒø~H5…u  ¿   ¸    è#úÿÿè¤èÿÿ„À„¤   èƒK  …Àt"H5uu  ¿    ¸    è÷ùÿÿÇEüıÿÿÿé€   èÏ  ‹ï¾  ƒø~H5ku  ¿   ¸    èÅùÿÿè¹Şÿÿ‹É¾  ƒø~H5^u  ¿   ¸    èŸùÿÿèVîÿÿ‹£¾  ƒø~H5Ru  ¿   ¸    èyùÿÿè¶`  ëÇEüüÿÿÿ‹EüÉÃUH‰åH‰}øH‹EøH‹ H‹UøH‹RH‰PH‹EøH‹@H‹UøH‹H‰H‹EøHÇ     H‹EøHÇ@    ]ÃUH‰åH‰}èH‰uàÇEü    ‹Eü‰Eøë)‹UüH‹EèHĞ¶ ¾ÀEø‹EøÁà
Eø‹EøÁè1EøƒEü‹EüH9EàwÎ‹EøÁàEø‹EøÁè1Eø‹EøÁàEø‹Eø]ÃUH‰åHƒì H‰}èH‹EèH‰Çè	×ÿÿH‰ÂH‹EèH‰ÖH‰Çèiÿÿÿ‰ÀH‰EøH‹Eø‰Çèp   H…Àu¸    ë¸   ÉÃUH‰åHƒìH‰}ø‹a½  ƒø~+H‹EøH‹PH‹EøH‹ H‰ÑH‰ÂH5t  ¿   ¸    è"øÿÿH‹EøH‰Çè°şÿÿH‹EøH‰ÇèÙÕÿÿÉÃUH‰åHƒì0‰}ÜH‹$½  H‰EèëdH‹EèH‰EğH‹EğH‰Eø‹è¼  ƒø~,H‹Eø‹H4H‹Uø‹EÜA‰ÈH‰Ñ‰ÂH5¾s  ¿   ¸    è¨÷ÿÿH‹Eø‹@49EÜuH‹EøëCH‹EèH‹ H‰EèH³¼  H9Eèu‹‡¼  ƒø~‹EÜ‰ÂH5®s  ¿   ¸    èX÷ÿÿ¸    ÉÃUH‰åHƒì0H‰}ØH‹EØH‰Çè¨ÕÿÿH‰ÂH‹EØH‰ÖH‰Çèşÿÿ‰ÀH‰EèH‹I¼  H‰EàëaH‹EàH‰EğH‹EğH‰Eø‹¼  ƒø~&H‹Eø‹P4H‹Eø‰ÑH‰ÂH5As  ¿   ¸    èÓöÿÿH‹Eø‹@4‰ÀH9EèuH‹EøëEH‹EàH‹ H‰EàHÛ»  H9Eàu’‹¯»  ƒø~H‹EèH‰ÂH5s  ¿   ¸    è~öÿÿ¸    ÉÃUH‰å‰}ÜÇEä    H‹‘»  H‰Eèë-H‹EèH‰EğH‹EğH‰Eø‹Eä;EÜuH‹Eøë!ƒEäH‹EèH‹ H‰EèHW»  H9EèuÆ¸    ]ÃUH‰åH=?»  èğ  ]ÃUH‰åHƒì ‰}ìH‰uà‹Eì‰ÇèyÿÿÿH‰EøHƒ}ø „õ   ‹êº  ƒø~"H‹Uø‹EìH‰Ñ‰ÂH5jr  ¿   ¸    è´õÿÿH‹EøH‹@H‹UàHƒÂH‰ÆH‰×èÈÓÿÿH‹Eø·P*H‹Eàf‰P&H‹Eø·P(H‹Eàf‰P$H‹EàÆ@( H‹EøH‹@H‰ÇèĞÓÿÿH‰ÂH‹EøH‹@H‰ÖH‰Çè,üÿÿ‰ÂH‹Eø‰P4‹Kº  ƒø~7H‹EøH‹HH‹Eà·@&·ĞH‹Eø‹@4I‰È‰Ñ‰ÂH5îq  ¿   ¸    è õÿÿH‹Eø‹P4H‹Eà‰¸   ë ‹Eì‰ÂH5÷q  ¿    ¸    èÑôÿÿ¸  ÉÃUH‰åHƒì‰}üH‰uğH‹Uğ‹EüH‰Ö‰Çè¡şÿÿHƒøuH‹Eğ‹ ë¸    ÉÃUH‰åHƒì0‰}ÜH‰uĞ‹EÜ‰ÇèuüÿÿH‰EøHƒ}ø „  ‹v¹  ƒø~+H‹EĞ‹0€  H‹Eø‹@4‰Ñ‰ÂH5q  ¿   ¸    è7ôÿÿH‹UĞH‹EøH‰ÖH‰Çè¡  H‰EğH‹EøH‹@H‹@H…À…a  Hƒ}ğ „V  H‹EøH‰Çè1S  ‰Eì‹ú¸  ƒø~8H‹EøH‹@H‹HH‹EøH‹@H‹ ‹UìI‰È‰ÑH‰ÂH5Lq  ¿   ¸    è®óÿÿƒ}ì …Ÿ   H‹EøH‰Çè6=  ‰Eìƒ}ì u/‹˜¸  ƒøb  ‹EÜ‰ÂH5Sq  ¿   ¸    èeóÿÿéB  ‹i¸  ƒø~‹Eì‰ÂH5Cq  ¿   ¸    è:óÿÿH‹EøH‹@HÇ@    H‹EğH‰Çè¸ùÿÿH‹EğH‰ÇèáĞÿÿHÇEğ    éç   ‹¸  ƒø~‹EÜ‰ÂH5q  ¿   ¸    èßòÿÿH‹EøH‹@HÇ@    H‹EğH‰Çè]ùÿÿH‹EğH‰Çè†ĞÿÿHÇEğ    éŒ   Hƒ}ğ u#‹¬·  ƒø~{H5àp  ¿   ¸    è‚òÿÿëc‹‰·  ƒø~XH‹EøH‹@H‹@H‰ÂH5æp  ¿   ¸    èPòÿÿë1‹W·  ƒø~‹EÜ‰ÂH5öp  ¿   ¸    è(òÿÿHÇEğ    ëH‹EğÉÃUH‰åè™R  ]ÃUH‰åèøD  H˜]ÃUH‰åHƒì ‰}ì‹Eì‰Çè8
  H‰EøHƒ}ø tH‹EøH‹@H‹@‹Uì‰ÖH‰Çèn6  ëH5¨p  ¿    ¸    è­ñÿÿ‹¶¶  ƒø~‹Eì‰ÂH5p  ¿   ¸    è‡ñÿÿ‹Eì‰Çèß  H˜ÉÃUH‰åHƒìP‰}ÜH‰uĞH‰UÈH‰MÀL‰E¸‹EÜ‰Çè£	  H‰EğÇEì    Hƒ}ğ t+H‹Eğ¶@ „ÀtH‹EğH‹@H‹@H‰Eøƒ}ì „   é÷   Hƒ}ğ t:H‹Eğ¶@ ƒğ„Àt+H‹Eğ‹@$‰ÂH5p  ¿    ¸    èâğÿÿHÇÀüÿÿÿé¹   Hƒ}ğ t!H‹Eğ‹@$‰ÂH5&p  ¿    ¸    è°ğÿÿëH5“o  ¿    ¸    è˜ğÿÿHÇÀüÿÿÿërH‹EĞ‹ ƒøu!H‹EĞ‹@‰ÂH‹MÀH‹EøH‰ÎH‰Çès/  ‰EìëCH‹EøHHH‹EÈH‹PH‹ H‰H‰QH‹EĞ‹ ¶ĞH‹EĞ‹@‰ÇH‹uÀH‹Eø‰Ñ‰úH‰ÇèN-  ‰Eì‹EìÉÃUH‰åH‰}èHÇEø    H‹EèH‹ H‰EğëHƒEøH‹EğH‹ H‰EğH‹EğH;EèuæH‹Eø]ÃUH‰åH‰}øH‹EøH‹ H‹UøH‹RH‰PH‹EøH‹@H‹UøH‹H‰H‹EøHÇ     H‹EøHÇ@    ]ÃUH‰åH=‹´  èlÿÿÿ]ÃUH‰åHƒì¿h€  è¢ÏÿÿH‰EøHƒ}ø u'‹q´  ƒø‹   H5Ñn  ¿   ¸    èCïÿÿës‹J´  ƒø~H‹EøH‰ÂH5×n  ¿   ¸    èïÿÿH‹Eøºh€  ¾    H‰Çè2ÎÿÿH‹EøÇ@ÿÿÿÿ‹´  ƒÀ‰„´  ‹~´  H‹Eø‰0€  H‹EøÆ€ €   H‹EøÉÃUH‰åHƒìH‰}øH‹EøH‰ÇèÌÿÿ‹¹³  ƒø~H‹EøH‰ÂH5jn  ¿   ¸    èˆîÿÿÉÃUH‰åHƒìH‰}ø‹³  ƒø~+H‹EøH‹PH‹EøH‹ H‰ÑH‰ÂH5@n  ¿   ¸    èBîÿÿH‹EøH‰ÇèXşÿÿH‹EøH‰ÇèbÿÿÿÉÃUH‰åH‰}øH‰uğH‹EøH‹UğH‰H‹EğH‹PH‹EøH‰PH‹EğH‹@H‹UøH‰H‹EğH‹UøH‰P]ÃUH‰åH‰}øH‹EøH‹ H‹UøH‹RH‰PH‹EøH‹@H‹UøH‹H‰H‹EøHÇ     H‹EøHÇ@    ]ÃUH‰å‰}ÜÇEä    H‹¥²  H‰Eèë;H‹EèH‰EğH‹EğH‰EøH‹Eø¶@ „ÀtH‹EøH‹@‹@49EÜuƒEäH‹EèH‹ H‰EèH]²  H9Eèu¸‹Eä]ÃUH‰åHƒì0‰}ÜH‹@²  H‰EèënH‹EèH‰EğH‹EğH‰EøH‹Eø¶@ „ÀtGH‹EøH‹@‹@49EÜu7‹ø±  ƒø~$H‹Eø‹@$‹UÜ‰Ñ‰ÂH5îl  ¿   ¸    èÀìÿÿH‹EøÆ@  H‹EèH‹ H‰EèHÅ±  H9Eèu…ÉÃUH‰åÇEô    H‹ª±  H‰EøëƒEôH‹EøH‹ H‰EøH±  H9Eøuä‹Eô]ÃUH‰å‹m±  P‰d±  ]ÃUH‰åHƒì H‰}èH‰uà¿(   èdÌÿÿH‰EøHƒ}ø trH‹EøH‹UèH‰PH‹EøH‹UàH‰Pè©ÿÿÿ‰ÂH‹Eø‰P$H‹EøÆ@ ‹±  ƒø~$H‹UàH‹EèH‰ÑH‰ÂH5Cl  ¿   ¸    èÍëÿÿH‹EøH5á°  H‰Çè“ıÿÿë/‹Á°  ƒø~$H‹UàH‹EèH‰ÑH‰ÂH5?l  ¿   ¸    è‰ëÿÿH‹EøÉÃUH‰åHƒì@H‰}ÈH‰uÀÆEß HÇEà    H‹°  Hx°  H9Ât{H‹l°  H‰Eèë_H‹EèH‰EğH‹EğH‰EàH‹Eà¶@ „Àt8H‹EÈ‹P4H‹EàH‹@‹@49Âu"H‹EÀ‹0€  H‹EàH‹@‹€0€  9ÂuÆEßëH‹EèH‹ H‰EèH °  H9Eèu”ëÆEß ¶Eßƒğ„À„†   ‹Ï¯  ƒø~"H‹EÀ‹€0€  ‰ÂH5†k  ¿   ¸    è™êÿÿH‹UÀH‹EÈH‰ÖH‰Çè7şÿÿH‰EøH‹EøH‰EàHƒ}ø tu‹|¯  ƒø~jH‹Eø‹@$H‹UøH‰Ñ‰ÂH5Pk  ¿   ¸    èBêÿÿëB‹I¯  ƒø~H‹Eà‹@$‰ÂH5Gk  ¿   ¸    èêÿÿH‹EàH‹UÀH‰PH‹EàH‹UÈH‰PH‹EàÉÃUH‰åHƒì‰}ü¶…¯  „Àtè@ıÿÿ9Eüu	ÆI¯  ë(‹Ø®  ƒø~è"ıÿÿ‰ÂH5öj  ¿   ¸    è§éÿÿ¶¯  ÉÃUH‰åHƒì0‰}Ü‹œ®  ƒø~‹EÜ‰ÂH5Ûj  ¿   ¸    èméÿÿ‹EÜ‰Çè²  H‰EğHƒ}ğ „œ  ‹EÜ‰Çè  H‹Eğ¶@ „À„  H‹EğH‹@‹@4‰Çèûÿÿ‰Eì‹.®  ƒø~(H‹EğH‹@‹@4‹Uì‰Ñ‰ÂH5ˆj  ¿   ¸    èòèÿÿƒ}ì…  ‹ñ­  ƒø~&H‹Eğ‹@$H‹UğH‰Ñ‰ÂH5j  ¿   ¸    è·èÿÿH‹EğH‹@H‰Eø‹´­  ƒø~!H‹EøH‹@H‰ÂH5­j  ¿   ¸    èèÿÿH‹EøH‹@H‰Çèd1  H‹EøÆ@8 ‹p­  ƒø~èºûÿÿ‰ÂH5j  ¿   ¸    è?èÿÿH‹EøH‹@HÇ@    ¿   è-şÿÿëS‹,­  ƒø~H5hj  ¿   ¸    èèÿÿ‹­  ƒø~èUûÿÿ‰ÂH5+j  ¿   ¸    èÚçÿÿ¿   èØıÿÿH‹EğH‰ÇèâùÿÿH‹EğH‰Çè‡Åÿÿ¸    ÉÃUH‰å‰}ÜH‹Â¬  H‰Eèë-H‹EèH‰EğH‹EğH‰EøH‹Eø‹@$9EÜuH‹EøëH‹EèH‹ H‰EèHˆ¬  H9EèuÆ¸    ]ÃUH‰åH‰}ØH‹l¬  H‰Eèë=H‹EèH‰EğH‹EğH‰EøH‹EØ‹0€  H‹EøH‹@‹€0€  9ÂuH‹EøëH‹EèH‹ H‰EèH"¬  H9Eèu¶¸    ]ÃUH‰å‰}ÜÇEä    H‹ ¬  H‰Eèë;H‹EèH‰EğH‹EğH‰EøH‹Eø¶@ „ÀtH‹EøH‹@‹@49EÜuƒEäH‹EèH‹ H‰EèH¸«  H9Eèu¸‹Eä]ÃUH‰åH‰}ø‰uô‹EôÁø‰ÂH‹EøHƒÀˆ‹EôÁø‰ÂH‹EøHƒÀˆ‹EôÁø‰ÂH‹EøHƒÀˆ‹Eô‰ÂH‹Eøˆ]ÃUH‰å‰}ü‹Õ«  9Eüu
ÇÆ«      ]ÃUH‰å‰}ì‹Eì=ñ   „™   =ñ   Aƒø„‰   ƒø…Àtlƒøt{ƒøütlë=à   tm=à   -   ƒøwgëZ=ä   tSë\=U  =Q  }C-   ƒøwDë7= P  t0= P  -    ƒøw*ë=   tëHÇEø   ëHÇEø   ë‹EìH˜H‰Eøë	HÇEø   H‹Eø]ÃUH‰åAVAUATSHìà  H‰½(üÿÿH‰µ üÿÿH‰•üÿÿH‰üÿÿD‰…üÿÿdH‹%(   H‰EØ1ÀÇ…@üÿÿ    H‹… üÿÿ¶ „À…œ   ƒ½üÿÿt2‹…üÿÿ¹   ‰ÂH5‚g  ¿    ¸    èÌäÿÿH‹…üÿÿÇ    ëOè­òÿÿ‰…@üÿÿ‹…@üÿÿ‰Çè…şÿÿ‰ÂH‹…üÿÿ‰‹£©  ƒø~!H‹…üÿÿ‹ ‰ÂH5lg  ¿   ¸    ènäÿÿH‹…üÿÿÇ    é!  H‹… üÿÿ¶ <…   ƒ½üÿÿt2‹…üÿÿ¹   ‰ÂH5Dg  ¿    ¸    èäÿÿH‹…üÿÿÇ     ë@èïíÿÿ‰ÂH‹…üÿÿ‰‹©  ƒø~%H‹…üÿÿ¶ ¾À‰ÂH55g  ¿   ¸    èÏãÿÿH‹…üÿÿÇ    éw   H‹… üÿÿ¶ <…­   ƒ½üÿÿt2‹…üÿÿ¹   ‰ÂH5g  ¿    ¸    èãÿÿH‹…üÿÿÇ     ë`H‹… üÿÿ‹@‰…„üÿÿ‹…„üÿÿ‰Çè]üÿÿ‰ÂH‹…üÿÿ‰‹Q¨  ƒø~-H‹…üÿÿ¶ ¾À‹•„üÿÿ‰Ñ‰ÂH5æf  ¿   ¸    èãÿÿH‹…üÿÿÇ    é¸  H‹… üÿÿ¶ <…?  H‹… üÿÿ‹@‰…Düÿÿ‹å§  ƒø~1H‹… üÿÿHƒÀ¶ ¾À‹•Düÿÿ‰Ñ‰ÂH5¾f  ¿   ¸    è âÿÿƒ½üÿÿt/‹…üÿÿ¹   ‰ÂH5Òf  ¿    ¸    ètâÿÿÇ…@üÿÿ   ë(H‹… üÿÿHƒÀ¶ ¾ÀH• ıÿÿH‰Ö‰Çè=ìÿÿ‰…@üÿÿH‹…üÿÿ‹•@üÿÿ‰‹…DüÿÿPH‹…üÿÿ‰ƒ½Düÿÿ)vA‹…DüÿÿH‹•üÿÿHJH‰Â¾    H‰Ïè$Áÿÿƒ½@üÿÿuH‹…üÿÿÇ R  Ç…Düÿÿ)   ‹•DüÿÿH‹…üÿÿHHH… ıÿÿH‰ÆH‰Ïè±Áÿÿég  H‹… üÿÿ¶ <…”  ƒ½üÿÿtLƒ½üÿÿtC‹…üÿÿ¹   ‰ÂH5f  ¿    ¸    èfáÿÿH‹…üÿÿHƒÀÇ     Ç…@üÿÿ   é  Ç…@üÿÿ   H‹… üÿÿ‹@‰…€üÿÿH‹… üÿÿHƒÀ¶ „À•Àˆ…?üÿÿ‹¦  ƒø~7H‹…(üÿÿ‹ˆ0€  ¶•?üÿÿ‹…€üÿÿA‰È‰Ñ‰ÂH5¯e  ¿   ¸    èÑàÿÿH‹•(üÿÿ‹…€üÿÿH‰Ö‰Çè%ìÿÿH‰…XıÿÿHƒ½Xıÿÿ u3H5¹e  ¿    ¸    è“àÿÿÇ…@üÿÿ  H‹…üÿÿHƒÀÇ     ëN‹¥  ƒø~"H‹…Xıÿÿ‹@$‰ÂH5§e  ¿   ¸    èIàÿÿÇ…@üÿÿ   H‹…üÿÿHPH‹…Xıÿÿ‹@$‰H‹…üÿÿ‹•@üÿÿ‰H‹…üÿÿÇ    éÁ  H‹… üÿÿ¶ <…²   ƒ½üÿÿt/‹…üÿÿ¹   ‰ÂH5Oe  ¿    ¸    èÉßÿÿÇ…@üÿÿ   ëPH‹… üÿÿ‹@‰…|üÿÿ‹¶¤  ƒø~‹…|üÿÿ‰ÂH5Je  ¿   ¸    è„ßÿÿ‹…|üÿÿ‰ÇèÙõÿÿÇ…@üÿÿ   ‹…@üÿÿ‰Çè@ùÿÿ‰ÂH‹…üÿÿ‰H‹…üÿÿÇ    éı  H‹… üÿÿ¶ <…L  Ç…@üÿÿ   ƒ½üÿÿw:‹…üÿÿ¹    ‰ÂH5éd  ¿    ¸    èûŞÿÿÇ…@üÿÿ   H‹…üÿÿÇ    ƒ½@üÿÿ…³  H‹… üÿÿHƒÀH‰…8ıÿÿH‹…8ıÿÿ‹ ‰…Hüÿÿ‹¿£  ƒø  H‹… üÿÿHƒÀ¶ D¶àH‹… üÿÿHƒÀ¶ ¶ØH‹… üÿÿHƒÀ¶ D¶ØH‹… üÿÿHƒÀ¶ D¶ĞH‹… üÿÿHƒÀ¶ D¶ÈH‹… üÿÿHƒÀ¶ D¶ÀH‹… üÿÿHƒÀ¶ ¶øH‹… üÿÿHƒÀ¶ ¶ğH‹… üÿÿHƒÀ¶ ¶ÈH‹… üÿÿHƒÀ
¶ D¶ğH‹… üÿÿHƒÀ	¶ D¶èH‹… üÿÿHƒÀ¶ ¶Ğ‹…HüÿÿHƒìATSASARAQAPWVQE‰ñE‰è‰Ñ‰ÂH5Òc  ¿   ¸    èœİÿÿHƒÄPH‹… üÿÿHƒÀH‰… üÿÿH‹… üÿÿH‰…@ıÿÿH‹… üÿÿHƒÀH‰…HıÿÿH‹…(üÿÿ‹0€  H‹…Hıÿÿ‰H‹… üÿÿHƒÀ¶ ¾À‰…`ıÿÿH‹… üÿÿ‹@‰…dıÿÿH‹… üÿÿHƒÀ H‰…˜üÿÿ‹…`ıÿÿ…ÀuhH‹…üÿÿÇ    ‹	¢  ƒø~‹…üÿÿ‰ÂH5…c  ¿   ¸    è×Üÿÿ‹à¡  ƒø¤   ‹…dıÿÿ‰ÂH5|c  ¿   ¸    èªÜÿÿé   ‹…`ıÿÿƒøu&H‹…üÿÿHƒÀH‰…˜üÿÿ‹…dıÿÿPH‹…üÿÿ‰ëP‹…`ıÿÿƒøuEH‹…üÿÿHƒÀH‰…˜üÿÿ‹…dıÿÿPH‹…üÿÿ‰‹N¡  ƒø~H5c  ¿   ¸    è$Üÿÿƒ½@üÿÿ…Y  ‹…`ıÿÿ…À…  ‹•üÿÿH‹… üÿÿHĞH‰…Pıÿÿ‹…üÿÿ‰…Lüÿÿ‹…dıÿÿƒÀ ‰…püÿÿÇ…tüÿÿ    ‹…Lüÿÿ;…püÿÿƒı   ½püÿÿ €  v%‹…püÿÿ¹ €  ‰ÂH5‚b  ¿    ¸    èŒÛÿÿë8‹…püÿÿ+…Lüÿÿ‰ÁH‹•PıÿÿH‹…(üÿÿ‰ÎH‰Çè¯Ôÿÿ‰…tüÿÿ‹…tüÿÿ…Lüÿÿ‹…Lüÿÿ;…püÿÿƒ‚   ‹•püÿÿ‹…Lüÿÿ‰Ñ‰ÂH5Hb  ¿    ¸    èÛÿÿÇ…@üÿÿ   H‹…üÿÿÇ    ëCƒ½üÿÿ t:‹…üÿÿ¹    ‰ÂH5Kb  ¿    ¸    èÕÚÿÿÇ…@üÿÿ   H‹…üÿÿÇ    ƒ½@üÿÿ…ª   H‹… üÿÿHƒÀ¶ <òuCH‹… üÿÿHƒÀ	¶ <Qu1‹*   …Àu‹…Hüÿÿ‰   ënÇ…@üÿÿ   H‹…üÿÿÇ    ëUH‹… üÿÿHƒÀ¶ <òuCH‹… üÿÿHƒÀ	¶ <Ru1‹ÕŸ  9…HüÿÿuÇÃŸ      ëÇ…@üÿÿ   H‹…üÿÿÇ    ƒ½@üÿÿ…ø  H‹˜üÿÿH‹• üÿÿHµ`ıÿÿ‹…HüÿÿA¸ˆ  ‰ÇèYèÿÿ‰…@üÿÿƒ½@üÿÿ t)‹Ì  ƒø~‹…@üÿÿ‰ÂH5Pa  ¿   ¸    èšÙÿÿH‹…üÿÿHƒÀH‰…@ıÿÿ‹‘  ƒøw  H‹…üÿÿ‹ ƒø†e  H‹…üÿÿ‹ ƒè‰…xüÿÿƒ½xüÿÿú  ƒ½xüÿÿ  ‹D  ƒø*  H‹…@ıÿÿHƒÀ¶ D¶àH‹…@ıÿÿHƒÀ
¶ ¶ØH‹…@ıÿÿHƒÀ	¶ D¶ØH‹…@ıÿÿHƒÀ¶ D¶ĞH‹…@ıÿÿHƒÀ¶ D¶ÈH‹…@ıÿÿHƒÀ¶ D¶ÀH‹…@ıÿÿHƒÀ¶ ¶øH‹…@ıÿÿHƒÀ¶ ¶ğH‹…@ıÿÿHƒÀ¶ ¶ÈH‹…@ıÿÿHƒÀ¶ D¶ğH‹…@ıÿÿHƒÀ¶ D¶èH‹…@ıÿÿ¶ ¶Ğ‹…dıÿÿHƒìATSASARAQAPWVQE‰ñE‰è‰Ñ‰ÂH5`  ¿   ¸    è%ØÿÿHƒÄPé  ‹%  ƒø  H‹…@ıÿÿHƒÀ¶ D¶ÈH‹…@ıÿÿHƒÀ¶ D¶ÀH‹…@ıÿÿHƒÀ¶ ¶øH‹…@ıÿÿHƒÀ¶ ¶ğH‹…@ıÿÿHƒÀ¶ ¶ÈH‹…@ıÿÿHƒÀ¶ D¶ØH‹…@ıÿÿHƒÀ¶ D¶ĞH‹…@ıÿÿ¶ ¶Ğ‹…dıÿÿHƒìAQAPWVQE‰ÙE‰Ğ‰Ñ‰ÂH5¢_  ¿   ¸    èT×ÿÿHƒÄ0ëL‹Wœ  ƒø~AH‹…@ıÿÿHƒÀ¶ ¶ÈH‹…@ıÿÿ¶ ¶Ğ‹…dıÿÿA‰È‰Ñ‰ÂH5˜_  ¿   ¸    è×ÿÿ‹…@üÿÿ‰ÇèÕğÿÿ‰ÂH‹…üÿÿ‰éŸ  H‹… üÿÿ¶ <…  Æ…=üÿÿƒ½üÿÿt#‹…üÿÿ¹   ‰ÂH5V_  ¿    ¸    è ÖÿÿH‹… üÿÿ¶@ˆ…>üÿÿ‹˜›  ƒø~(¾•=üÿÿ¾…>üÿÿ‰Ñ‰ÂH5b_  ¿   ¸    è\ÖÿÿH‹…üÿÿÇ     H‹…üÿÿÆ H•`ıÿÿHüÿÿH…ˆüÿÿH‰ÎH‰Çè{ØÿÿH‹…ˆüÿÿ‰ÂH‹…üÿÿHƒÀ‰ÖH‰ÇèyïÿÿH‹…üÿÿ‰ÂH‹…üÿÿHƒÀ‰ÖH‰Çè[ïÿÿH‹…`ıÿÿ‰ÂH‹…üÿÿHƒÀ‰ÖH‰Çè=ïÿÿH‹…üÿÿÇ    és  H‹… üÿÿº   H5à^  H‰Çè½³ÿÿ…À…¸   ‹Ÿš  ƒø~&H‹…(üÿÿH4€  H‰ÂH5Ã^  ¿   ¸    èeÕÿÿèEßÿÿ‰ÂHEH5Í^  H‰Ç¸    èÅ¶ÿÿ‹Oš  ƒø~+H‹…(üÿÿH4€  HEH‰ÁH5¦^  ¿   ¸    èÕÿÿHUH‹…üÿÿH‰ÖH‰Çè)³ÿÿHEH‰Çè]³ÿÿ‰ÂH‹…üÿÿ‰é˜  H‹… üÿÿº   H5|^  H‰Çèâ²ÿÿ…À…`  ÇEˆ    ÆEŒ H‹… üÿÿH‰…0ıÿÿÇ…Püÿÿ    HUˆH‹…0ıÿÿH‰ÖH‰Çè¡µÿÿH‰…¨üÿÿë~H ıÿÿ‹…PüÿÿHcĞH‰ĞHÁàHĞHÁàHÁH‹…¨üÿÿºP   H‰ÆH‰ÏèP²ÿÿ‹…PüÿÿHcĞH‰ĞHÁàHĞHÁàH]àHØH-ñ  Æ  HEˆH‰Æ¿    è(µÿÿH‰…¨üÿÿƒ…PüÿÿHƒ½¨üÿÿ tƒ½Püÿÿkÿÿÿ‹í˜  ƒø~&H‹…(üÿÿH4€  H‰ÂH5‰]  ¿   ¸    è³ÓÿÿH… ıÿÿHƒÀPH‰Çèÿ´ÿÿ‰ÂH…pıÿÿH‰Æ‰×èÃŞÿÿ‰…lüÿÿƒ½lüÿÿ „ª   ·…–ıÿÿ·ğ·…”ıÿÿ·ÈH…pıÿÿHx‹•lüÿÿHEI‰ùA‰ğH5>]  H‰Ç¸    è¶´ÿÿ‹@˜  ƒø~+H‹…(üÿÿH4€  HEH‰ÁH5]  ¿   ¸    èÓÿÿ‹
˜  ƒø~iH…pıÿÿHƒÀH‰ÂH5"]  ¿   ¸    èÒÒÿÿëC‹Ù—  ƒø~+H… ıÿÿHƒÀPH‰Çè´ÿÿ‰ÂH5ù\  ¿   ¸    èšÒÿÿHEfÇ 0
Æ@ HUH‹…üÿÿH‰ÖH‰Çè¦°ÿÿHEH‰ÇèÚ°ÿÿ‰ÂH‹…üÿÿ‰é  H‹… üÿÿº   H5©\  H‰Çè_°ÿÿ…À…v  ÇEˆ    ÆEŒ H‹… üÿÿH‰… ıÿÿÇ…Tüÿÿ    HUˆH‹… ıÿÿH‰ÖH‰Çè³ÿÿH‰…°üÿÿë~H ıÿÿ‹…TüÿÿHcĞH‰ĞHÁàHĞHÁàHÁH‹…°üÿÿºP   H‰ÆH‰ÏèÍ¯ÿÿ‹…TüÿÿHcĞH‰ĞHÁàHĞHÁàH]àHØH-ñ  Æ  HEˆH‰Æ¿    è¥²ÿÿH‰…°üÿÿƒ…TüÿÿHƒ½°üÿÿ tƒ½TüÿÿkÿÿÿH…`ıÿÿH• ıÿÿHJPH‰ÂH5²[  H‰Ï¸    è—±ÿÿ‹A–  ƒø~<H‹…(üÿÿ‹ˆ0€  ‹…`ıÿÿH‹•(üÿÿHÂ4€  A‰È‰ÁH5w[  ¿   ¸    èñĞÿÿ‹…`ıÿÿ‰ÂH‹…(üÿÿH‰Æ‰×èCÜÿÿH‰…(ıÿÿHƒ½(ıÿÿ t_‹Ğ•  ƒø~0H‹…(ıÿÿ‹@$H‹•(üÿÿHÂ4€  ‰ÁH5J[  ¿   ¸    èŒĞÿÿH‹…(ıÿÿ‹P$HEH5ñY  H‰Ç¸    èé±ÿÿë>‹q•  ƒø~&H‹…(üÿÿH4€  H‰ÂH5%[  ¿   ¸    è7ĞÿÿHEfÇ 0
Æ@ ‹3•  ƒø~+H‹…(üÿÿH4€  HEH‰ÁH5[  ¿   ¸    èôÏÿÿHUH‹…üÿÿH‰ÖH‰Çè®ÿÿHEH‰ÇèA®ÿÿ‰ÂH‹…üÿÿ‰é|  H‹… üÿÿº   H5ÖZ  H‰ÇèÆ­ÿÿ…À…×  ÇEˆ    ÆEŒ H‹… üÿÿH‰…ıÿÿÇ…Xüÿÿ    HUˆH‹…ıÿÿH‰ÖH‰Çè…°ÿÿH‰…¸üÿÿë~H ıÿÿ‹…XüÿÿHcĞH‰ĞHÁàHĞHÁàHÁH‹…¸üÿÿºP   H‰ÆH‰Ïè4­ÿÿ‹…XüÿÿHcĞH‰ĞHÁàHĞHÁàH]àHØH-ñ  Æ  HEˆH‰Æ¿    è°ÿÿH‰…¸üÿÿƒ…XüÿÿHƒ½¸üÿÿ tƒ½XüÿÿkÿÿÿH…`ıÿÿH• ıÿÿHJPH‰ÂH5àY  H‰Ï¸    èş®ÿÿ‹¨“  ƒø~,‹…`ıÿÿH‹•(üÿÿHÂ4€  ‰ÁH5®Y  ¿   ¸    èhÎÿÿ‹…`ıÿÿ‰Çè]Üÿÿ‰…@üÿÿƒ½@üÿÿ uEHEfÇ 1
Æ@ ‹H“  ƒø~:H‹…(üÿÿH4€  HEH‰ÁH5Y  ¿   ¸    è	ÎÿÿëHEfÇ 0
Æ@ HUH‹…üÿÿH‰ÖH‰Çè¬ÿÿHEH‰ÇèG¬ÿÿ‰ÂH‹…üÿÿ‰é‚
  H‹… üÿÿº   H5QY  H‰ÇèÌ«ÿÿ…À…¥  ÇEƒ    ÆE‡ H‹… üÿÿH‰… ıÿÿÇ…\üÿÿ    HUƒH‹… ıÿÿH‰ÖH‰Çè‹®ÿÿH‰…Àüÿÿë~H ıÿÿ‹…\üÿÿHcĞH‰ĞHÁàHĞHÁàHÁH‹…ÀüÿÿºP   H‰ÆH‰Ïè:«ÿÿ‹…\üÿÿHcĞH‰ĞHÁàHĞHÁàH]àHØH-ñ  Æ  HEƒH‰Æ¿    è®ÿÿH‰…Àüÿÿƒ…\üÿÿHƒ½Àüÿÿ tƒ½\üÿÿkÿÿÿH…üÿÿH• ıÿÿHJPH‰ÂH5æW  H‰Ï¸    è­ÿÿ‹…üÿÿ‰ÇèçäÿÿH‰…ıÿÿHƒ½ıÿÿ „  H‹…ıÿÿ¶@ „À„û  H‹…ıÿÿH‹@H‹@H…À„ã  ‹a‘  ƒø~ H‹…ıÿÿH‰ÂH5ëW  ¿   ¸    è-Ìÿÿ‹6‘  ƒø~&H‹…(üÿÿH4€  H‰ÂH5ÚW  ¿   ¸    èüËÿÿ‹…üÿÿ‰ÁH‹…ıÿÿH‹@H‹@H•`ıÿÿ‰ÎH‰Çèâ  ‰…@üÿÿH‹…ıÿÿH‹@H‹@H‰…ıÿÿH‹…ıÿÿ·@^f=K7tH‹…ıÿÿ·@^f=R7uHEˆÇ 2.1 é¢   H‹…ıÿÿ·@^f=N7t3H‹…ıÿÿ·@^f=O7t"H‹…ıÿÿ·@^f=S7tH‹…ıÿÿ·@^f=T7uHEˆfÇ 3 ëSH‹…ıÿÿ·@^f=H7uHEˆfÇ 2 ë7H‹…ıÿÿ·@^f=V7tH‹…ıÿÿ·@^f=W7uHEˆÇ PWR ë	HEˆfÇ ? H‹…ıÿÿ·@^D·ÀH‹…ıÿÿ·@\·ø¶…cıÿÿ¶ğ¶…bıÿÿD¶È¶…`ıÿÿD¶ĞHMˆ‹•@üÿÿHEHƒìAPWVE‰ĞH5‡V  H‰Ç¸    èú«ÿÿHƒÄ ëHEfÇ 0
Æ@ ‹q  ƒø~+H‹…(üÿÿH4€  HEH‰ÁH5XV  ¿   ¸    è2ÊÿÿHUH‹…üÿÿH‰ÖH‰ÇèK¨ÿÿHEH‰Çè¨ÿÿ‰ÂH‹…üÿÿ‰éº  H‹… üÿÿº   H52V  H‰Çè¨ÿÿ…À…™  ÇEˆ    ÆEŒ H‹… üÿÿH‰…øüÿÿÇ…`üÿÿ    HUˆH‹…øüÿÿH‰ÖH‰ÇèÃªÿÿH‰…Èüÿÿë~H ıÿÿ‹…`üÿÿHcĞH‰ĞHÁàHĞHÁàHÁH‹…ÈüÿÿºP   H‰ÆH‰Ïèr§ÿÿ‹…`üÿÿHcĞH‰ĞHÁàHĞHÁàH]àHØH-ñ  Æ  HEˆH‰Æ¿    èJªÿÿH‰…Èüÿÿƒ…`üÿÿHƒ½Èüÿÿ tƒ½`üÿÿkÿÿÿ‹  ƒø~&H‹…(üÿÿH4€  H‰ÂH5;U  ¿   ¸    èÕÈÿÿèÅÖÿÿ‰…@üÿÿ‹•@üÿÿHEH53R  H‰Ç¸    è+ªÿÿ‹µ  ƒø~+H‹…(üÿÿH4€  HEH‰ÁH5U  ¿   ¸    èvÈÿÿHUH‹…üÿÿH‰ÖH‰Çè¦ÿÿHEH‰ÇèÃ¦ÿÿ‰ÂH‹…üÿÿ‰éş  H‹… üÿÿº   H5ßT  H‰ÇèH¦ÿÿ…À…P  ÇEˆ    ÆEŒ H‹… üÿÿH‰…èüÿÿÇ…düÿÿ    HUˆH‹…èüÿÿH‰ÖH‰Çè©ÿÿH‰…Ğüÿÿë~H ıÿÿ‹…düÿÿHcĞH‰ĞHÁàHĞHÁàHÁH‹…ĞüÿÿºP   H‰ÆH‰Ïè¶¥ÿÿ‹…düÿÿHcĞH‰ĞHÁàHĞHÁàH]àHØH-ñ  Æ  HEˆH‰Æ¿    è¨ÿÿH‰…Ğüÿÿƒ…düÿÿHƒ½Ğüÿÿ tƒ½düÿÿkÿÿÿH…`ıÿÿH• ıÿÿHJPH‰ÂH5bR  H‰Ï¸    è€§ÿÿ‹*Œ  ƒø~&H‹…(üÿÿH4€  H‰ÂH5¾S  ¿   ¸    èğÆÿÿ‹…`ıÿÿ‰ÇèlĞÿÿH‰…ğüÿÿHƒ½ğüÿÿ „ˆ   H‹…ğüÿÿH‹@H…Àtx‹Ç‹  ƒø~*H‹…ğüÿÿ‹P4‹…`ıÿÿ‰Ñ‰ÂH5‡S  ¿   ¸    è‰Æÿÿ‹…`ıÿÿ‰ÂH‹…ğüÿÿH‹@‰ÖH‰Çè  ‰…@üÿÿ‹•@üÿÿHEH5ÏO  H‰Ç¸    èÇ§ÿÿëHEfÇ 0
Æ@ ‹B‹  ƒø~+H‹…(üÿÿH4€  HEH‰ÁH5!S  ¿   ¸    èÆÿÿHUH‹…üÿÿH‰ÖH‰Çè¤ÿÿHEH‰ÇèP¤ÿÿ‰ÂH‹…üÿÿ‰é‹  H‹… üÿÿº   H5ùR  H‰ÇèÕ£ÿÿ…À…¿  ÇEˆ    ÆEŒ H‹… üÿÿH‰…àüÿÿÇ…hüÿÿ    HUˆH‹…àüÿÿH‰ÖH‰Çè”¦ÿÿH‰…Øüÿÿë~H ıÿÿ‹…hüÿÿHcĞH‰ĞHÁàHĞHÁàHÁH‹…ØüÿÿºP   H‰ÆH‰ÏèC£ÿÿ‹…hüÿÿHcĞH‰ĞHÁàHĞHÁàH]àHØH-ñ  Æ  HEˆH‰Æ¿    è¦ÿÿH‰…Øüÿÿƒ…hüÿÿHƒ½Øüÿÿ tƒ½hüÿÿkÿÿÿH‹…(üÿÿH4€  H• ıÿÿHƒÂPH‰ÖH‰Çèã¢ÿÿH… ıÿÿHƒÀPH‰Çè£ÿÿHPÿH‹…(üÿÿ¶„4€  <
u&H… ıÿÿHƒÀPH‰Çèæ¢ÿÿHPÿH‹…(üÿÿÆ„4€   HEfÇ 1
Æ@ ‹`‰  ƒø~+H‹…(üÿÿH4€  HEH‰ÁH5Q  ¿   ¸    è!ÄÿÿHUH‹…üÿÿH‰ÖH‰Çè:¢ÿÿHEH‰Çèn¢ÿÿ‰ÂH‹…üÿÿ‰é©   ‹øˆ  ƒø~ H‹… üÿÿH‰ÂH5RQ  ¿   ¸    èÄÃÿÿHEH»0 unknowH¾n_commanH‰H‰pfÇ@d
Æ@ ‹¤ˆ  ƒø~HEH‰ÂH5)Q  ¿   ¸    èsÃÿÿHUH‹…üÿÿH‰ÖH‰ÇèŒ¡ÿÿHEH‰ÇèÀ¡ÿÿ‰ÂH‹…üÿÿ‰H‹EØdH3%(   tèÀ¡ÿÿHeà[A\A]A^]ÃUH‰åH‰}ø‰uô‹EôÁø‰ÂH‹EøHƒÀˆ‹EôÁø‰ÂH‹EøHƒÀˆ‹EôÁø‰ÂH‹EøHƒÀˆ‹Eô‰ÂH‹Eøˆ]ÃUH‰åHƒì0H‰}èH‰uà‰UÜ‰ÈˆEØÇEü   ÇEø    Hƒ}è u H5xP  ¿    ¸    è’Âÿÿ¸üÿÿÿé‘  H‹EèH‹@H…Àu H5sP  ¿    ¸    èeÂÿÿ¸üÿÿÿéd  H‹EèHxH‹Eè¶@¶ğH‹EèH‹@‹UüA¸¸  ‰ÑH‰úH‰Çèœ.  9Eüt(‹.‡  ƒø~H5AP  ¿   ¸    èÂÿÿÇEøüÿÿÿƒ}Ü ù   ƒ}ø …ï   €}Ø u^H‹Eè¶@¶ğH‹EèH‹@‹MÜH‹UàA¸¸  H‰Çè-.  9EÜ„¸   ‹»†  ƒø~H5ïO  ¿   ¸    è‘ÁÿÿÇEøüÿÿÿé‹   €}ØuWH‹Eè¶@¶ğH‹EèH‹@‹MÜH‹UàA¸¸  H‰ÇèÉ-  9EÜtX‹[†  ƒø~H5·O  ¿   ¸    è1ÁÿÿÇEøüÿÿÿë.‹1†  ƒø~¶EØ‰ÂH5¯O  ¿   ¸    èÁÿÿÇEøüÿÿÿ‹EøÉÃUH‰åHƒì H‰}øH‰uğ‰UìHƒ}ø u H5›O  ¿    ¸    èÅÀÿÿ¸üÿÿÿé„   H‹EøH‹@H…ÀuH5O  ¿    ¸    è˜Àÿÿ¸üÿÿÿëZH‹Eø¶@¶ğH‹EøH‹@‹MìH‹UğA¸¸  H‰ÇèÛ,  9Eìt(‹m…  ƒø~H5O  ¿   ¸    èCÀÿÿ¸üÿÿÿë¸    ÉÃUH‰åHƒìH‰}øH‹EøHƒÀº    ¾    H‰Çè>ŸÿÿH‹EøHƒÀ;º    ¾    H‰Çè$ŸÿÿÉÃUH‰åHƒì0H‰}è‰uäH‰UØHƒ}è u H5 O  ¿    ¸    èÂ¿ÿÿ¸üÿÿÿéã  H‹EèH‰ÇèwÿÿÿÆEûH‹Eè·@^f=K7t H‹Eè·@^f=R7tH‹Eè·@^f=H7…|  H‹EèÆ@ñ‹EäH‹UèHƒÂ'‰ÆH‰×è9üÿÿ¶UûH‹EèHp;H‹Eè‰Ñº   H‰Çèiüÿÿ‰Eüƒ}ü t‹EüéX  H‹Eè¶@;Àè‰ÂH‹EØˆH‹Eè¶@;¶ÀÁàƒà<‰ÂH‹Eè¶@<Àè	Ğ‰ÂH‹EØˆPH‹Eè¶@<ƒà?‰ÂH‹EØˆPH‹EØÆ@ H‹EØÆ@ H‹EØÆ@ H‹Eè¶@>¶ÀÁà‰ÂH‹Eè¶@=¶À	Ğ‰ÂH‹Eèf‰P\H‹Eè¶@@¶ÀÁà‰ÂH‹Eè¶@?¶À	Ğ‰ÂH‹Eèf‰P^H‹Eè·@^f=H7„k  H‹EØ¶@<v?H‹EØ¶@<w3H‹EØ¶@<t'H‹EØ¶@<tH5­M  ¿    ¸    è¾ÿÿé   H‹EØ¶PH‹EØˆPH‹EØÆ@ é  H‹EèÆ@û‹EäH‹UèHƒÂ'‰ÆH‰×è½úÿÿ¶UûH‹EèHp;H‹Eè‰Ñº   H‰Çèíúÿÿ‰Eüƒ}ü t‹EüéÜ   H‹Eè¶P;H‹EØˆH‹Eè¶P<H‹EØˆPH‹Eè¶P=H‹EØˆPH‹Eè¶P>H‹EØˆPH‹Eè¶P?H‹EØˆPH‹Eè¶P@H‹EØˆPH‹EØÆ@ H‹EØÆ@ H‹Eè¶@D¶ÀÁà‰ÂH‹Eè¶@C¶À	Ğ‰ÂH‹Eèf‰P\H‹Eè¶@F¶ÀÁà‰ÂH‹Eè¶@E¶À	Ğ‰ÂH‹Eèf‰P^H‹Eè·P\H‹EØf‰PH‹Eè·P^H‹EØf‰P
¸    ÉÃUH‰åHƒì0H‰}èH‰uà‰UÜHƒ}è u H5iL  ¿    ¸    è£¼ÿÿ¸üÿÿÿé“   H‹EèH‰ÇèXüÿÿH‹EèÆ@õ‹EÜH‹UèHƒÂ'‰ÆH‰×èLùÿÿH‹EèHp;H‹Eè¹   º   H‰Çè}ùÿÿ‰Eüƒ}ü uH‹Eè¶P;H‹Eàˆ‹D  ƒø~'H‹Eà¶ ¶Ğ‹Eü‰Ñ‰ÂH5ÿK  ¿   ¸    è	¼ÿÿ‹EüÉÃUH‰åHƒì H‰}è‰uäHƒ}è uH5L  ¿    ¸    èØ»ÿÿ¸üÿÿÿëxH‹EèH‰ÇèûÿÿH‹EèÆ@òH‹EèÆ@!‹EäH‹UèHƒÂ'‰ÆH‰×è|øÿÿH‹Eè¹   º    ¾    H‰Çè°øÿÿ‰Eü‹‹€  ƒø~‹Eü‰ÂH5ºK  ¿   ¸    è\»ÿÿ‹EüÉÃUH‰åHƒì H‰}è‰uädH‹%(   H‰Eø1ÀHƒ}è u H5¢K  ¿    ¸    è»ÿÿ¸üÿÿÿéè   ‹UäHMóH‹EèH‰ÎH‰Çè)şÿÿ‰Eôƒ}ô t‹EôéÁ   ‹ô  ƒø~¶Eó¶À‰ÂH5uK  ¿   ¸    èÁºÿÿ¶Eó<…ˆ   ‹UäH‹Eè‰ÖH‰Çè şÿÿ‰Eô‹ª  ƒø~‹Eô‰ÂH5ÙJ  ¿   ¸    è{ºÿÿƒ}ô t‹EôëF‹UäHMóH‹EèH‰ÎH‰Çè‡ıÿÿ‰Eô‹`  ƒø~¶Eó¶À‰ÂH5áJ  ¿   ¸    è-ºÿÿ‹EôH‹MødH3%(   tè¥˜ÿÿÉÃUH‰åHƒì H‰}è‰uäHƒ}è uH5¾J  ¿    ¸    èè¹ÿÿ¸üÿÿÿëxH‹EèH‰Çè ùÿÿH‹EèÆ@óH‹EèÆ@‹EäH‹UèHƒÂ'‰ÆH‰×èŒöÿÿH‹Eè¹   º    ¾    H‰ÇèÀöÿÿ‰Eü‹›~  ƒø~‹Eü‰ÂH5jJ  ¿   ¸    èl¹ÿÿ‹EüÉÃUH‰åHƒì H‰}è‰uädH‹%(   H‰Eø1ÀHƒ}è u H5RJ  ¿    ¸    è,¹ÿÿ¸üÿÿÿé¾   ‹UäHMóH‹EèH‰ÎH‰Çè9üÿÿ‰Eôƒ}ô t‹Eôé—   ‹~  ƒø~¶Eó¶À‰ÂH5…I  ¿   ¸    èÑ¸ÿÿ¶Eó„Àub‹UäH‹Eè‰ÖH‰Çè¤şÿÿ‰Eôƒ}ô t‹EôëF‹UäHMóH‹EèH‰ÎH‰ÇèÁûÿÿ‰Eô‹š}  ƒø~¶Eó¶À‰ÂH5I  ¿   ¸    èg¸ÿÿ‹EôH‹MødH3%(   tèß–ÿÿÉÃUH‰åHƒì H‰}è‰uäHƒ}è u H5xI  ¿    ¸    è"¸ÿÿ¸üÿÿÿé  H‹Eè¶@`<w H‹Eè¶@`<…¼   H‹Eè¶@a<†¬   ‹UäH‹Eè‰ÖH‰Çètşÿÿ‰Eüƒ}ü t‹Eüé½   H‹EèH‰Çè‰÷ÿÿH‹EèÆ@òH‹EèÆ@I‹EäH‹UèHƒÂ'‰ÆH‰×èuôÿÿH‹EèHp;H‹Eè¹   º   H‰Çè¦ôÿÿ‰Eü‹|  ƒø~‹Eü‰ÂH5ØH  ¿   ¸    èR·ÿÿƒ}ü t‹Eüë:¸    ë3‹I|  ƒø~#H‹Eè¶@a¶À‰ÂH5ÀH  ¿   ¸    è·ÿÿ¸   ÉÃUH‰åHƒìH‰}øHƒ}ø „‹   H‹EøH‹@H…Àt~‹ğ{  ƒø~H5¬H  ¿   ¸    èÆ¶ÿÿH‹EøH‹@¾    H‰Çè0•ÿÿ‹º{  ƒø~!H‹EøH‹@H‰ÂH5ŠH  ¿   ¸    è…¶ÿÿH‹EøH‹@H‰Çèd•ÿÿH‹EøHÇ@    ¸    ÉÃUH‰åHƒì@H‰}ÈdH‹%(   H‰Eø1ÀH‹EÈH‹@H‰EàHƒ}à uH54H  ¿    ¸    è¶ÿÿév  H‹EàH‹@H…ÀuH5LH  ¿    ¸    èöµÿÿéN  H‹EÈ·P*H‹Eàf‰P^‹êz  ƒø~!H‹EàH‹@H‰ÂH5SH  ¿   ¸    èµµÿÿH‹EàH‹@¾    H‰Çè
  H‹EàHpH‹EàHHH‹EàHPH‹EàH‹@I‰ğH‰Æ¿    è±  ‰EÜƒ}Ü tH5'H  ¿    ¸    èQµÿÿé©  HUìH‹Eà¾    H‰ÇèEõÿÿ‰EÜƒ}Ü …w  H‹Eà·@^f=H7uEH‹Eà·@^·ğ¶Eí¶È¶Eî¶Ğ¶Eì¶ÀA‰ñA‰È‰Ñ‰ÂH5ÚG  ¿   ¸    èÜ´ÿÿé  H‹Eà·@^f=K7tH‹Eà·@^f=R7uEH‹Eà·@^·ğ¶Eï¶È¶Eî¶Ğ¶Eì¶ÀA‰ñA‰È‰Ñ‰ÂH5™G  ¿   ¸    è{´ÿÿé¦  H‹Eà·@^f=N7tH‹Eà·@^f=T7uEH‹Eà·@^·ğ¶Eï¶È¶Eî¶Ğ¶Eì¶ÀA‰ñA‰È‰Ñ‰ÂH5`G  ¿   ¸    è´ÿÿéE  H‹Eà·@^f=S7tH‹Eà·@^f=O7uZH‹Eà·@^·ğ¶Eí¶È¶EğD¶À¶Eï¶ø¶Eî¶Ğ¶Eì¶ÀVQE‰ÁA‰ø‰Ñ‰ÂH5G  ¿   ¸    è¨³ÿÿHƒÄéÏ   H‹Eà·@^f=V7tH‹Eà·@^f=W7uWH‹Eà·@^·ğ¶Eñ¶È¶EğD¶À¶Eï¶ø¶Eî¶Ğ¶Eì¶ÀVQE‰ÁA‰ø‰Ñ‰ÂH5ÀF  ¿   ¸    è2³ÿÿHƒÄë\H‹Eà·@^·ø¶Eñ¶ğ¶Eí¶È¶EğD¶È¶EïD¶À¶Eî¶Ğ¶Eì¶ÀHƒìWVQ‰Ñ‰ÂH5ŠF  ¿   ¸    èÔ²ÿÿHƒÄ ¶UìH‹EàˆP`¶UîH‹EàˆPa¸    ëMH‹EàÆ@`H‹EàÆ@a‹¬w  ƒø~!H‹EÈH‹@H‰ÂH5]F  ¿   ¸    èw²ÿÿH‹EàH‰Çè`ûÿÿ¸üÿÿÿH‹MødH3%(   tèáÿÿÉÃUH‰åH‰}øH‰uğH‹EğH‹H‹EøH‰H‹EøH‹UğH‰PH‹EğH‹ H‹UøH‰PH‹EğH‹UøH‰]ÃUH‰åH‰}øH‰uğH‹EøH‹UğH‰H‹EğH‹PH‹EøH‰PH‹EğH‹@H‹UøH‰H‹EğH‹UøH‰P]ÃUH‰åH‰}øH‹EøH‹ H‹UøH‹RH‰PH‹EøH‹@H‹UøH‹H‰H‹EøHÇ     H‹EøHÇ@    ]ÃUH‰åHƒìH‰}øH‰uğH‹EøH‹ H‹UøH‹RH‰PH‹EøH‹@H‹UøH‹H‰H‹UğH‹EøH‰ÖH‰ÇèéşÿÿÉÃUH‰åHƒì H‰}ø‰ĞH‰MèD‰Eä‰òˆUôf‰Eğ‹Eä·È·uğ¶Eô€Ì·ĞH‹}èH‹Eøhè  QI‰ùA‰ğ‰Ñº   ¾€   H‰ÇèJ’ÿÿHƒÄÉÃUH‰åHƒì H‰}èH‰uàH‹Eè¶ ¶À‰Eüƒ}üuRÇEø    ëA‹EøƒÀÀHcĞH‹EèHĞ¶ ¶À‹UøÒHcÊH‹UàHÑ‰ÂH5 D  H‰Ï¸    èë‘ÿÿƒEøƒ}ø~¹ë=ƒ}ü2u7ÇEø    ë(‹EøƒÀÀHcĞH‹EèHĞ¶‹EøHcÈH‹EàHÈˆƒEøƒ}ø~ÒH‹EàHƒÀÆ  ¸    ÉÃUH‰åHƒì@H‰}ÈH‰uÀdH‹%(   H‰Eø1ÀHUàH‹EÈH‰ÖH‰Çè¾ÿÿ‰EÜƒ}Ü uPÇEØ    ë/·Eèf=ƒu!·Uê‹EØH H‹EÀHÈ· f9Âu¸   ëTƒEØ‹EØH H‹EÀHĞ· f…Àu»ë3‹t  ƒø~(‹EÜ‰ÇèÀÿÿH‰Â‹EÜ‰ÁH5‘C  ¿   ¸    èS¯ÿÿ¸    H‹MødH3%(   tèÉÿÿÉÃUH‰åHƒì H‰}øH‰uğ‰UìH‰Màƒ}ìu/‹$t  ƒø~H‹EğH‰ÂH5]C  ¿   ¸    èó®ÿÿè×¼ÿÿëWƒ}ìu6‹ïs  ƒø~H‹EğH‰ÂH5:C  ¿   ¸    è¾®ÿÿH‹EğH‰Çèç   ë‹Eì‰ÂH5%C  ¿    ¸    è•®ÿÿ¸    ÉÃUH‰åHƒìH=&t  èIÿÿ…Ày
¸üÿÿÿéŸ   èÿÿH‰EøHƒ}ø ti‹es  ƒø~H‹EøH‹HH‹Eø·@·øH‹Eø·@·ğH‹Eø·@·ĞH‹Eø· ·ÀHƒìQA‰ùA‰ğ‰Ñ‰ÂH5ŸB  ¿   ¸    èù­ÿÿHƒÄë!‹ür  ƒø~H5§B  ¿   ¸    èÒ­ÿÿ¸    ÉÃUH‰åHì   H‰½xÿÿÿdH‹%(   H‰Eø1ÀHUH‹…xÿÿÿH‰ÖH‰ÇèsÿÿH‹…xÿÿÿH5•A  H‰Çèmıÿÿ„ÀuUHU€H‹…xÿÿÿH‰ÖH‰Çèc‹ÿÿ¶E ¶ğH‹E€HU°¹@   H‰ÇègŒÿÿHE°H‰ÇèëµÿÿH‰EˆHƒ}ˆ tH‹EˆH‰ÇèÁ´ÿÿ¸   H‹MødH3%(   tè›‹ÿÿÉÃUH‰åHì   dH‹%(   H‰Eø1ÀÆ…ãşÿÿ Ç…èşÿÿ    H‹r  H‰…ÿÿÿé  H‹…ÿÿÿH‰…@ÿÿÿH‹…@ÿÿÿH‰…Hÿÿÿ‹¹q  ƒø~,H‹…Hÿÿÿ‹P4H‹…Hÿÿÿ‰ÑH‰ÂH5gA  ¿   ¸    èy¬ÿÿH‹…HÿÿÿÆ@9 H‹…HÿÿÿH‹@H‹@H…À„—   ‹_q  ƒø~$H‹…HÿÿÿH‹@H‰ÂH5EA  ¿   ¸    è'¬ÿÿ‹0q  ƒø~(H‹…HÿÿÿH‹@H‹@H‰ÂH5:A  ¿   ¸    èô«ÿÿH‹…HÿÿÿH‹@H‹@H‰ÇèÌŠÿÿH‹…HÿÿÿH‹@HÇ@    H‹…HÿÿÿÆ@;H‹…ÿÿÿH‹ H‰…ÿÿÿHÖp  H9…ÿÿÿ…ÎşÿÿH‹:q  H•øşÿÿH‰ÖH‰Çè‹ÿÿ‰…ìşÿÿ‹„p  ƒø~‹…ìşÿÿ‰ÂH5¸@  ¿   ¸    èR«ÿÿÇ…äşÿÿ    ép  H‹…øşÿÿ‹•äşÿÿHcÒHÁâHĞH‹ H•PÿÿÿH‰ÖH‰Çèö‹ÿÿ‰…ôşÿÿƒ½ôşÿÿ tN‹p  ƒø  ‹…ôşÿÿ‰Çè;‹ÿÿH‰Æ‹•äşÿÿ‹…ôşÿÿA‰Ğ‰ÁH‰òH5U@  ¿   ¸    è¿ªÿÿéÜ  H‹…øşÿÿ‹•äşÿÿHcÒHÁâHĞH‹ H5¨>  H‰Çè€úÿÿ„ÀuK‹–o  ƒø£  ·…Zÿÿÿ·È·…Xÿÿÿ·Ğ‹…äşÿÿA‰È‰Ñ‰ÂH5%@  ¿   ¸    èGªÿÿég  H‹…øşÿÿ‹•äşÿÿHcÒHÁâHĞH‹ H• ÿÿÿH‰ÖH‰Çèˆÿÿ‰…ôşÿÿƒ½ôşÿÿ …f  ¶…`ÿÿÿ¶ğH‹… ÿÿÿHU°A¸@   H‰Ñº	  H‰Çè¢øÿÿ…Ày=‹İn  ƒø~‹…äşÿÿ‰ÂH5Á?  ¿   ¸    è«©ÿÿH‹… ÿÿÿH‰Çè‹ˆÿÿé½  H•pÿÿÿHE°H‰ÖH‰Çè¬øÿÿ‹Šn  ƒø~ H…pÿÿÿH‰ÂH5”?  ¿   ¸    èV©ÿÿH…pÿÿÿH‰Çè•°ÿÿƒğ„À„K  ¿@   èa‰ÿÿH‰…8ÿÿÿHƒ½8ÿÿÿ ty¿h   èF‰ÿÿH‰ÂH‹…8ÿÿÿH‰PH‹…8ÿÿÿH‹@H…ÀunH5A?  ¿    ¸    èã¨ÿÿH‹…8ÿÿÿH‹@H…ÀtH‹…8ÿÿÿH‹@H‰Çè†ÿÿH‹…8ÿÿÿH‰Çè€†ÿÿÆ…ãşÿÿëH5ğ>  ¿    ¸    è’¨ÿÿÆ…ãşÿÿ¶…ãşÿÿƒğ„À„B  H‹…8ÿÿÿHH H…Pÿÿÿº   H‰ÆH‰ÏèVˆÿÿH‹…øşÿÿ‹•äşÿÿHcÒHÁâHÂH‹…8ÿÿÿH‹@H‹H‰H…pÿÿÿH‰ÇèÏ‰ÿÿH‰ÂH‹…8ÿÿÿH‰PH‹…8ÿÿÿH‹@H‹• ÿÿÿH‰PH‹…8ÿÿÿÆ@8 H‹…8ÿÿÿÆ@9‹ïl  ƒø~EH‹…8ÿÿÿ·@*·ÈH‹…8ÿÿÿ·@(·ĞH‹…8ÿÿÿH‹@A‰È‰ÑH‰ÂH5$>  ¿   ¸    è–§ÿÿ‹Ÿl  ƒø~9H‹…8ÿÿÿH‹@H‹PH‹…8ÿÿÿH‹@H‹ H‰ÑH‰ÂH5 >  ¿   ¸    èR§ÿÿH‹…8ÿÿÿH5sl  H‰Çè/õÿÿé]  ‹@l  ƒø~ H…pÿÿÿH‰ÂH5
>  ¿   ¸    è§ÿÿH‹… ÿÿÿH‰Çèì…ÿÿÆ…ãşÿÿ é  ‹úk  ƒø~ H…pÿÿÿH‰ÂH5ô=  ¿   ¸    èÆ¦ÿÿH…pÿÿÿH‰Çèf¯ÿÿH‰…8ÿÿÿHƒ½8ÿÿÿ „È  ‹«k  ƒø~YH‹…8ÿÿÿH‹@H‹pH‹…8ÿÿÿH‹@H‹H‹…8ÿÿÿ·@*·ĞH‹…8ÿÿÿ·@(·ÀI‰ñI‰È‰Ñ‰ÂH5¤=  ¿   ¸    è>¦ÿÿH‹…8ÿÿÿÆ@9H‹…øşÿÿ‹•äşÿÿHcÒHÁâHÂH‹…8ÿÿÿH‹@H‹H‰H‹…8ÿÿÿH‹@H‹• ÿÿÿH‰PH‹…8ÿÿÿÆ@8 ‹ój  ƒø  H‹…8ÿÿÿH‹@H‹PH‹…8ÿÿÿH‹@H‹ H‰ÑH‰ÂH5P=  ¿   ¸    è¢¥ÿÿéÃ   H…pÿÿÿH‰Çè=®ÿÿH‰…8ÿÿÿHƒ½8ÿÿÿ t9‹†j  ƒø~YH‹…8ÿÿÿ‹@4H•pÿÿÿH‰Ñ‰ÂH5$=  ¿   ¸    èF¥ÿÿë+‹Mj  ƒø~ H…pÿÿÿH‰ÂH57=  ¿   ¸    è¥ÿÿ‹"j  ƒø~4‹…ôşÿÿ‰ÇèP…ÿÿH‰Â‹…ôşÿÿ‰ÁH5"=  ¿   ¸    èà¤ÿÿëëƒ…äşÿÿ‹…äşÿÿ;…ìşÿÿŒ~ùÿÿH…PÿÿÿH‰…PÿÿÿH…PÿÿÿH‰…Xÿÿÿ‹®i  ƒø~%H=Âi  ès´ÿÿH‰ÂH5Ò<  ¿   ¸    èu¤ÿÿH‹i  H‰…ÿÿÿH‹…ÿÿÿH‹ H‰…ÿÿÿé>  H‹…ÿÿÿH‰…(ÿÿÿH‹…(ÿÿÿH‰…0ÿÿÿH‹…0ÿÿÿ¶@9ƒğ„ÀtU‹,i  ƒø~,H‹…0ÿÿÿ‹P4H‹…0ÿÿÿ‰ÑH‰ÂH5j<  ¿   ¸    èì£ÿÿH‹…0ÿÿÿH•PÿÿÿH‰ÖH‰ÇèRòÿÿéœ  H‹…0ÿÿÿ¶@8ƒğ„À„¸   H‹…0ÿÿÿ¶@;ƒğ„À„¢   ‹«h  ƒø~$H‹…0ÿÿÿH‹@H‰ÂH5)<  ¿   ¸    ès£ÿÿ‹|h  ƒø~9H‹…0ÿÿÿH‹@H‹PH‹…0ÿÿÿH‹@H‹ H‰ÑH‰ÂH5<  ¿   ¸    è/£ÿÿH‹…0ÿÿÿH‹@H‹@H‰Çè‚ÿÿH‹…0ÿÿÿH‹@HÇ@    éÎ   H‹…0ÿÿÿ¶@;„À„»   H‹…0ÿÿÿÆ@8‹ëg  ƒø~(H‹…0ÿÿÿH‹@H‹@H‰ÂH5Å;  ¿   ¸    è¯¢ÿÿ‹¸g  ƒø~$H‹…0ÿÿÿH‹@H‰ÂH5¾;  ¿   ¸    è€¢ÿÿH‹…0ÿÿÿH‰Çèìÿÿ‰…ğşÿÿƒ½ğşÿÿ t0H‹…0ÿÿÿH‹@H‹@‹•ğşÿÿ‰ÑH‰ÂH5 ;  ¿    ¸    è2¢ÿÿH‹…ÿÿÿH‰…ÿÿÿH‹…ÿÿÿH‹ H‰…ÿÿÿH;g  H9…ÿÿÿ…®ıÿÿH‹…PÿÿÿH‰…ÿÿÿH‹…ÿÿÿH‹ H‰…ÿÿÿé¸   H‹…ÿÿÿH‰…ÿÿÿH‹…ÿÿÿH‰… ÿÿÿ‹Èf  ƒø~0H‹… ÿÿÿH‹PH‹… ÿÿÿ‹@4H‰Ñ‰ÂH5:;  ¿   ¸    è„¡ÿÿH‹… ÿÿÿ‹@4‰Çè@´ÿÿH‹… ÿÿÿH‰ÇèœïÿÿH‹… ÿÿÿH‹@H‰Çè ÿÿH‹… ÿÿÿH‰ÇèÿÿH‹…ÿÿÿH‰…ÿÿÿH‹…ÿÿÿH‹ H‰…ÿÿÿH…PÿÿÿH9…ÿÿÿ…4ÿÿÿ‹f  ƒø~%H=,f  èİ°ÿÿH‰ÂH5Ä:  ¿   ¸    èß ÿÿ‹…èşÿÿH‹MødH3%(   tèTÿÿÉÃUH‰åHƒì H‰}èH‹EèH‹@HPH‹EèH‹@H‹ H‰ÖH‰Çè”~ÿÿ‰Eü‹Eüƒøütuƒøü
ƒøõté¿   ƒøıt7…À„€   é­   ‹re  ƒøÓ   H5B:  ¿   ¸    èD ÿÿé¸   ‹He  ƒø¬   H5H:  ¿   ¸    è ÿÿé‘   ‹e  ƒø…   H5^:  ¿   ¸    èğŸÿÿëm‹÷d  ƒø~eH‹EèH‹@H‹@H‰ÂH5d:  ¿   ¸    è¾Ÿÿÿë>‹Åd  ƒø~6‹Eü‰ÇèöÿÿH‰Â‹Eü‰ÁH5T:  ¿   ¸    è‰Ÿÿÿëë
ëëë‹EüÉÃUH‰åHìğ   dH‹%(   H‰Eø1ÀÆ…ÿÿÿ Æ…ÿÿÿ ‹Vd  ƒø~H5:  ¿   ¸    è,ŸÿÿH‹Ìd  H• ÿÿÿH‰ÖH‰Çè"ÿÿ‰…ÿÿÿ‹d  ƒø~‹…ÿÿÿ‰ÂH5ê9  ¿   ¸    èäÿÿÇ…ÿÿÿ    éÀ  H‹… ÿÿÿ‹•ÿÿÿHcÒHÁâHĞH‹ H•PÿÿÿH‰ÖH‰Çèˆÿÿ‰…ÿÿÿƒ½ÿÿÿ tN‹£c  ƒøk  ‹…ÿÿÿ‰ÇèÍ~ÿÿH‰Æ‹•ÿÿÿ‹…ÿÿÿA‰Ğ‰ÁH‰òH59  ¿   ¸    èQÿÿé,  H‹… ÿÿÿ‹•ÿÿÿHcÒHÁâHĞH‹ H5:2  H‰Çèîÿÿ„ÀuK‹(c  ƒøó  ·…Zÿÿÿ·È·…Xÿÿÿ·Ğ‹…ÿÿÿA‰È‰Ñ‰ÂH5·3  ¿   ¸    èÙÿÿé·  H‹… ÿÿÿ‹•ÿÿÿHcÒHÁâHĞH‹ H•(ÿÿÿH‰ÖH‰Çè§{ÿÿ‰…ÿÿÿƒ½ÿÿÿ …:  ¶…`ÿÿÿ¶ğH‹…(ÿÿÿHU°A¸@   H‰Ñº	  H‰Çè4ìÿÿ…Ày=‹ob  ƒø~‹…ÿÿÿ‰ÂH5S3  ¿   ¸    è=ÿÿH‹…(ÿÿÿH‰Çè|ÿÿé  H•pÿÿÿHE°H‰ÖH‰Çè>ìÿÿ‹b  ƒø~ H…pÿÿÿH‰ÂH5&3  ¿   ¸    èèœÿÿH…pÿÿÿH‰Çè'¤ÿÿƒğ„À„²  ¿@   èó|ÿÿH‰…HÿÿÿHƒ½Hÿÿÿ ty¿h   èØ|ÿÿH‰ÂH‹…HÿÿÿH‰PH‹…HÿÿÿH‹@H…ÀunH5ã7  ¿    ¸    èuœÿÿH‹…HÿÿÿH‹@H…ÀtH‹…HÿÿÿH‹@H‰Çè!zÿÿH‹…HÿÿÿH‰ÇèzÿÿÆ…ÿÿÿëH5’7  ¿    ¸    è$œÿÿÆ…ÿÿÿ¶…ÿÿÿƒğ„À„m  H‹…HÿÿÿHH H…Pÿÿÿº   H‰ÆH‰Ïèè{ÿÿH‹… ÿÿÿ‹•ÿÿÿHcÒHÁâHÂH‹…HÿÿÿH‹@H‹H‰H…pÿÿÿH‰Çèa}ÿÿH‰ÂH‹…HÿÿÿH‰PH…pÿÿÿH‰ÇèzÿÿH‰ÂH…pÿÿÿH‰ÖH‰Çèa¢ÿÿ‰ÂH‹…Hÿÿÿ‰P4‹}`  ƒø~DH‹…HÿÿÿH‹HH‹…Hÿÿÿ·@*·ĞH‹…Hÿÿÿ·@(·ÀI‰È‰Ñ‰ÂH5Ë6  ¿   ¸    è%›ÿÿH‹…HÿÿÿH‹@H‹•(ÿÿÿH‰PH‹…HÿÿÿÆ@8 ‹`  ƒø~9H‹…HÿÿÿH‹@H‹PH‹…HÿÿÿH‹@H‹ H‰ÑH‰ÂH5¦6  ¿   ¸    èÀšÿÿH‹…HÿÿÿH5á_  H‰ÇèèÿÿÆ…ÿÿÿé‚   ‹§_  ƒø~ H…pÿÿÿH‰ÂH5™6  ¿   ¸    èsšÿÿH‹…(ÿÿÿH‰ÇèSyÿÿÆ…ÿÿÿ ë?‹d_  ƒø~4‹…ÿÿÿ‰Çè’zÿÿH‰Â‹…ÿÿÿ‰ÁH5d2  ¿   ¸    è"šÿÿëëƒ…ÿÿÿ‹…ÿÿÿ;…ÿÿÿŒ.ûÿÿ€½ÿÿÿ „  H‹… ÿÿÿ¾    H‰ÇèÑzÿÿH‹
_  H‰…0ÿÿÿéà   H‹…0ÿÿÿH‰…8ÿÿÿH‹…8ÿÿÿH‰…@ÿÿÿH‹…@ÿÿÿ¶@8ƒğ„À„   ‹¦^  ƒø~$H‹…@ÿÿÿH‹@H‰ÂH5Ç5  ¿   ¸    èn™ÿÿ‹w^  ƒø~9H‹…@ÿÿÿH‹@H‹PH‹…@ÿÿÿH‹@H‹ H‰ÑH‰ÂH5 5  ¿   ¸    è*™ÿÿH‹…@ÿÿÿH‹@H‹@H‰ÇèxÿÿH‹…@ÿÿÿH‹@HÇ@    H‹…0ÿÿÿH‹ H‰…0ÿÿÿH^  H9…0ÿÿÿ…ÿÿÿ¶…ÿÿÿH‹MødH3%(   tèOwÿÿÉÃUH‰å‹{^  ‰Æ¿    è—xÿÿH‹H^  H‰ÇèXyÿÿ]ÃUH‰åHƒì0H‰}Ø‰uÔdH‹%(   H‰Eø1ÀHÇEè    ÇEàÿÿÿÿH‹EØH‰ÇèyÿÿH‰Eğ‹b]  ƒø~"‹UÔH‹EØ‰ÑH‰ÂH5Ú4  ¿   ¸    è,˜ÿÿHUàH‹EØH‰ÖH‰Çè¸wÿÿ‰Eäƒ}ä u‹EÔ¶ÈHUèH‹Eğ‰ÎH‰ÇèWwÿÿ‰Eäë3‹ü\  ƒø~(‹Eä‰Çè-xÿÿH‰Â‹Eä‰ÁH5¶4  ¿   ¸    èÀ—ÿÿƒ}ä …²   H‹EèH…À„¥   H‹Eè¶@¶Ğ‹Eà9Â„ƒ   ‹œ\  ƒø~#H‹Eè¶@¶À‰ÂH5‡4  ¿   ¸    èe—ÿÿH‹Eè¶@¶ĞH‹EØ‰ÖH‰ÇèÛwÿÿ‰Eäƒ}ä t3‹L\  ƒø~(‹Eä‰Çè}wÿÿH‰Â‹Eä‰ÁH5V4  ¿   ¸    è—ÿÿH‹EèH‰ÇèCvÿÿƒ}ä t&‹\  ƒø~‹Eä‰ÂH5F4  ¿   ¸    èØ–ÿÿ‹EäH‹MødH3%(   tèPuÿÿÉÃUH‰åHƒì`‰}ÌH‰uÀH‰U¸H‰M°L‰E¨dH‹%(   H‰Eø1ÀH‹EÀH‰Çè8wÿÿH‰EèH‹E¸Æ  H‹E°Æ  H‹E¨Æ  HUØH‹Eè¾    H‰Çèºuÿÿ‰EĞƒ}Ğ uRƒ}Ì xH‹EØ¶@¶À9EÌ|o‹E[  ƒø~(H‹EØ¶@¶Ğ‹EÌ‰Ñ‰ÂH5§3  ¿   ¸    è	–ÿÿÇEĞüÿÿÿë3‹	[  ƒø~(‹EĞ‰Çè:vÿÿH‰Â‹EĞ‰ÁH5«3  ¿   ¸    èÍ•ÿÿƒ}Ğ …Ê   H‹EØH‹@‹UÌHcÒHÁâHĞH‹ H‰EàÇEÔ    é   H‹EàH‹@‹UÔHcÒHÁâHĞH‰EğH‹Eğ¶@¶ÀƒàƒøuWH‹Eğ¶@„Ày&ƒ}Ô uH‹Eğ¶PH‹E¸ˆë<H‹Eğ¶PH‹E¨ˆë,H‹Eğ¶@„ÀxH‹Eğ¶PH‹E°ˆëÇEĞüÿÿÿëÇEĞüÿÿÿƒEÔH‹Eà¶@¶À9EÔŒ^ÿÿÿƒ}Ğ …<  ‹øY  ƒø~#H‹Eà¶@¶À‰ÂH5Ş2  ¿   ¸    èÁ”ÿÿH‹Eà¶@¶ĞH‹EÀ‰ÖH‰Çè§uÿÿ‰EĞƒ}Ğ „è   ‹EĞƒøûtƒøütQƒøút)ëm‹Y  ƒø   H5 2  ¿   ¸    èb”ÿÿëi‹iY  ƒø~aH5µ2  ¿   ¸    è?”ÿÿëI‹FY  ƒø~AH5Â2  ¿   ¸    è”ÿÿë)‹#Y  ƒø~!H5Í2  ¿   ¸    èù“ÿÿë	ëëë‹öX  ƒø~(‹EĞ‰Çè'tÿÿH‰Â‹EĞ‰ÁH5°2  ¿   ¸    èº“ÿÿÇEĞüÿÿÿH‹EØH‰Çèærÿÿ‹EĞH‹MødH3%(   tèrÿÿÉÃUH‰åHƒì0H‰}è‰ğH‰UØ‰MàD‰EÔˆEädH‹%(   H‰Eø1ÀÇEğ    D‹EÔ¶uäH}ğ‹MàH‹UØH‹EèE‰ÁI‰øH‰Çè¦sÿÿ‰Eôƒ}ô „Ì   ‹3X  ƒø~‹Eô‰ÂH5"2  ¿   ¸    è“ÿÿƒ}ôüu-‹X  ƒø~H52  ¿   ¸    èİ’ÿÿÇEğÿÿÿÿé¬   ƒ}ôùu1‹ÔW  ƒø—   ‹Eğ‹Uà‰Ñ‰ÂH52  ¿   ¸    èœ’ÿÿëu‹£W  ƒø~(‹Eô‰ÇèÔrÿÿH‰Â‹Eô‰ÁH52  ¿   ¸    èg’ÿÿÇEğÿÿÿÿë9‹Eğ9Eà~1‹_W  ƒø~&‹Uğ‹Mà‹EôA‰È‰Ñ‰ÂH52  ¿   ¸    è%’ÿÿ‹EğH‹MødH3%(   tèpÿÿÉÃf.„     AWAVI‰×AUATL%.Q  UH-.Q  SA‰ıI‰öL)åHƒìHÁıèooÿÿH…ít 1Û„     L‰úL‰öD‰ïAÿÜHƒÃH9İuêHƒÄ[]A\A]A^A_Ãf.„     óÃ  HƒìHƒÄÃ         ctrl_handler %d Ctrl-C event    Could not set control handler : %d      The posix signal handler is installed   EXIT server     Entering non_blocking_accept_main ask_to_kill asked select failed. Error = %d   select failed. Error = %d (EINTR)       No connections/data in the last %ld seconds. ask_to_kill cancelled listening state : %d evaluate_auto_kill after listening accept error List of SockInfo %p     help version debug port auto-kill log_output hvd::l:p:a Parse param : %d --auto_exit  4 ***debug_level %s --log_output %s --log_output %s2 7184 ***port %s stlink-server
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
      Refresh: libusb_open success %s Refresh: Malloc error new stlink NOT added      Refresh: Add device %s to USB list: VID 0x%04X, PID 0x%04X      new libusb_device = %p, libusb_handle = %p      Refresh: Malloc error libusb_close STLink %s    Refresh: keep stlink device unchanged in device list %s Found VID 0x%04X, PID 0x%04X, libusb_device = %p, libusb_handle = %p    Updated libusb_device = %p, libusb_handle = %p  Refresh : unusable stlink device, key 0x%x for serial %s        Refresh : unusable stlink device %s Error libusb_open (%s, %d) count stlink_usb_list :%ld       move usb device to usb_delete_list %p, usb_key 0x%x     Refresh: libusb_close usb Device %s     close usb libusb_device = %p, libusb_handle = %p        usb already opened. libusb_handle %p    Refresh: keep libub_open after refresh %s       Refresh: Unable to claim interface again for libusb_handle %p, error %d Refresh: remove from USB list usb_key 0x%x, %s Refresh: List USB :%ld   libusb_open Error: Memory allocation failure    libusb_open Error: The user has insufficient permissions        libusb_open Error: The device has been disconnected     libusb_open OK, libusb dev_handle %p libusb_open Error (%s, %d) libusb_get_device_list entry    libusb_get_device_list found %d device  Error libusb_get_device_descriptor (%s, %d) for device %d       Init refresh : Malloc error new stlink NOT added        Add to stlink USB list: VID 0x%04X, PID 0x%04X, serial %s       Init refresh : new libusb_device = %p, libusb_handle = %p       Init refresh : Malloc error libusb_close STLink %s libusb_close USB device %s   libusb_close USB libusb_device %p, libusb_handle %p     libusb_get_configuration for dev_handle = %p, configuration = %d        Error libusb_get_config_descriptor (%s, %d) libusb_set_configuration : %d       Error libusb_set_configuration (%s, %d) libusb_mgt_set_configuration : return %d        libusb_mgt_claim_interface : interface %d > bNumInterfaces %d   Error libusb_get_config_descriptor (%s, %d) in claim interface libusb_claim_interface %d        libusb_claim_interface error LIBUSB_ERROR_NOT_FOUND     libusb_claim_interface error LIBUSB_ERROR_BUSY  libusb_claim_interface error LIBUSB_NO_DEVICE libusb_claim_interface error      Error libusb_claim_interface (%s, %d)   libusb_bulk_transfer: Error %d  libusb_bulk_transfer: Error USB device disconnected     libusb_bulk_transfer: Error timeout, transferred %d/%d bytes    libusb_bulk_transfer: Error (%s, %d)    libusb_bulk_transfer: No error (%d) but transferred %d/%d bytes ;  b   °=ÿÿh  ğAÿÿ   Bÿÿ8  
Cÿÿ¨  dCÿÿÈ  5Dÿÿè  MDÿÿ  ¬Dÿÿ(  êDÿÿD  &Jÿÿh  _Mÿÿˆ  ¤Mÿÿ¨  «MÿÿÈ  ÍMÿÿè  wNÿÿ  ­Tÿÿ(  ÌUÿÿH  ßWÿÿh  <Yÿÿˆ  Ä\ÿÿ¨  \^ÿÿÈ  é^ÿÿè  ñ_ÿÿ  àaÿÿ(  bÿÿH  Gbÿÿh  ¦dÿÿˆ  #eÿÿ¨  ‹fÿÿÈ  Òfÿÿè  ?gÿÿ  gÿÿ(  êgÿÿH   hÿÿh  ziÿÿˆ  Öiÿÿ¨  èiÿÿÈ  'kÿÿè  \kÿÿ  Úmÿÿ(  æmÿÿH  ómÿÿh  xnÿÿˆ  Öoÿÿ¨  pÿÿÈ  Zpÿÿè  lpÿÿ	  )qÿÿ(	  mqÿÿH	  Êqÿÿh	  rÿÿˆ	  Vrÿÿ¨	  ¾rÿÿÈ	  Tsÿÿè	  sÿÿ
  ¢sÿÿ(
  ntÿÿH
  ùuÿÿh
  Svÿÿˆ
  @xÿÿ¨
  •xÿÿÈ
  ûxÿÿè
  cyÿÿ  ²yÿÿ(  ÑyÿÿH  ™zÿÿh  Íœÿÿ  ÿÿ°  üÿÿĞ  ¼Ÿÿÿğ  ÿŸÿÿ  £ÿÿ0  í£ÿÿP  š¤ÿÿp  İ¥ÿÿ  Š¦ÿÿ°  £§ÿÿĞ  æ¨ÿÿğ  ©ÿÿ  ¡­ÿÿ0  ä­ÿÿP  )®ÿÿp  p®ÿÿ  »®ÿÿ°  ¯ÿÿĞ  à¯ÿÿğ  ¹°ÿÿ  c±ÿÿ0  &²ÿÿP  ç²ÿÿp  .¿ÿÿ  |Àÿÿ°  3ÇÿÿĞ  [Çÿÿğ  2Éÿÿ  cÌÿÿ0  ğÍÿÿP  `Îÿÿ˜             zR x      À>ÿÿ+                  zR x  $      @:ÿÿ@   FJw€ ?;*3$"       D   X>ÿÿ              \   Z?ÿÿZ    A†CU     |   ”?ÿÿÑ    A†CÌ     œ   E@ÿÿ    A†CS      ¼   =@ÿÿ_    A†CZ     Ü   |@ÿÿ>    A†C       ø   @ÿÿ<   A†C7          ¶Eÿÿ9   A†C4    <  ÏHÿÿE    A†C@     \  ôHÿÿ    A†CB      |  ÛHÿÿ"    A†C]      œ  İHÿÿª    A†C¥     ¼  gIÿÿ6   A†C1    Ü  }Oÿÿ   A†C    ü  |Pÿÿ   A†C      oRÿÿ]   A†CX    <  ¬Sÿÿˆ   A†Cƒ    \  Wÿÿ˜   A†C“    |  ŒXÿÿ    A†Cˆ     œ  ùXÿÿ   A†C    ¼  áYÿÿï   A†Cê    Ü  °[ÿÿ+    A†Cf      ü  »[ÿÿ<    A†Cw        ×[ÿÿ_   A†CZ    <  ^ÿÿ}    A†Cx     \  s^ÿÿh   A†Cc    |  »_ÿÿG    A†CB     œ  â_ÿÿm    A†Ch     ¼  /`ÿÿN    A†CI     Ü  ]`ÿÿ]    A†CX     ü  š`ÿÿ¶    A†C±       0aÿÿÚ    A†CÕ     <  êaÿÿ\    A†CW     \  &bÿÿ    A†CM      |  bÿÿ?   A†C:    œ  7cÿÿ5    A†Cp      ¼  Lcÿÿ~   A†Cy    Ü  ªeÿÿ    A†CG      ü  –eÿÿ    A†CH        ƒeÿÿ…    A†C€     <  èeÿÿ^   A†CY    \  &gÿÿ=    A†Cx      |  CgÿÿG    A†CB     œ  jgÿÿ    A†CM      ¼  \gÿÿ½    A†C¸     Ü  ùgÿÿD    A†C      ü  hÿÿ]    A†CX       ZhÿÿE    A†C@     <  hÿÿG    A†CB     \  ¦hÿÿh    A†Cc     |  îhÿÿ–    A†C‘     œ  diÿÿ9    A†Ct      ¼  }iÿÿ    A†CP      Ü  riÿÿÌ    A†CÇ     ü  jÿÿ‹   A†C†      ‰kÿÿZ    A†CU     <  Ãkÿÿí   A†Cè    \  mÿÿU    A†CP     |  Åmÿÿf    A†Ca     œ  nÿÿh    A†Cc     ¼  SnÿÿO    A†CJ     Ü  ‚nÿÿ    A†CZ      ü  nÿÿÈ    A†CÃ  $     )oÿÿ4"   A†CNŒƒ!"   D  5‘ÿÿO    A†CJ     d  d‘ÿÿà   A†CÛ    „  $“ÿÿÀ    A†C»     ¤  Ä“ÿÿC    A†C~      Ä  ç“ÿÿ   A†C    ä  æ–ÿÿÏ    A†CÊ     	  •—ÿÿ­    A†C¨     $	  "˜ÿÿC   A†C>    D	  E™ÿÿ­    A†C¨     d	  Ò™ÿÿ   A†C    „	  ËšÿÿC   A†C>    ¤	  î›ÿÿ©    A†C¤     Ä	  wœÿÿ   A†C    ä	  i ÿÿC    A†C~      
  Œ ÿÿE    A†C@     $
  ± ÿÿG    A†CB     D
  Ø ÿÿK    A†CF     d
  ¡ÿÿa    A†C\     „
  D¡ÿÿÄ    A†C¿     ¤
  è¡ÿÿÙ    A†CÔ     Ä
  ¡¢ÿÿª    A†C¥     ä
  +£ÿÿÃ    A†C¾       Î£ÿÿÁ    A†C¼     $  o¤ÿÿG   A†CB    D  –°ÿÿN   A†CI    d  Ä±ÿÿ·   A†C²    „  [¸ÿÿ(    A†Cc      ¤  c¸ÿÿ×   A†CÒ    Ä  ºÿÿ1   A†C,    ä  +½ÿÿ‚   A†C} D     ˜¾ÿÿe    BBE B(ŒH0†H8ƒM@r8A0A(B BBB    L  À¾ÿÿ                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  à      0«              Œ !            5«               !            =«                     d       C«                     p       H«                     a       R«                     l                                       Mµ      Uµ      ]µ      eµ      mµ      uµ                                         \                          °             „©             Pú                           Xú                    õşÿo    ˜             X
             Ø      
       /                                          ı             H                           h             ˜             Ğ      	                            ûÿÿo          şÿÿo    (      ÿÿÿo           ğÿÿo    ˆ      ùÿÿo                                                                                           pû                      æ      ö                  &      6      F      V      f      v      †      –      ¦      ¶      Æ      Ö      æ      ö                  &      6      F      V      f      v      †      –      ¦      ¶      Æ      Ö      æ      ö                  &      6      F      V      f      v      †      –      ¦      ¶      Æ      Ö      æ      ö                  &      6      F      V      f      v      †      –      ¦      ¶      Æ      Ö      æ      ö                                                                                     !      !      !                   0 !     0 !     @ !     @ !     GCC: (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0 ,             *      +                      ,    í       U      ñ                      ,    o       F%      9                      ,    P"       (      ı                      ,    š2       |9      ë                      ,    Å8       g=      D                      ,    ¸?       «A      ˆ	                      ,    ®O       3K      ·                      ,    ˜Y       êL      ™                      ,    1i       ƒT      j#                      ,    Ø{       íw      Ô                      ,    ’Œ       Áˆ      D                       é       Ã    Ä  *      +          4   Ø8   ­   .  í  ²   0  b   %?   N  ¿  'F   int G  )M   ç   ç  †M       ŒŠ   R  Š   F  x   E  Š   Ğ   7  Ğ   Ş  Øõ\  	n   öx    	   ûÊ   	  üÊ   	  ıÊ   	Ô  şÊ    	¶  ÿÊ   (
ª   Ê   0
…   Ê   8
_  Ê   @
  Ê   H
F  Ê   P
  Ê   X
  ”  `
   
š  h
  x   p
]  x   t
¦  œ   x
k  F   €
€  T   ‚
"      ƒ
O  °  ˆ
ª  %§   
X  -È   ˜
_  .È    
f  /È   ¨
m  0È   °
t  2-   ¸
•  3x   À
{  5¶  Ä Ç  š|   ”  	`  ¡”   	ç  ¢š  	ÿ  ¦x    c  Ü   Ğ   °  8     \  Ğ   Æ  8    ¨  u  ?Æ    @Æ  u   AÆ  ×   ï  ‡  ‡š  e  ˆš  ø  ‰š  è  x   õ  1   &  è  1  €V  	™  V    8   f  8      A  ¨   â   R  4¤  	6  6x    	Ê  7x      ¤  @  	Ò    	x   Â  	È    C   	¯  
8ş  	\  
:²    	   
;‘    
?+  	ç  
Ax    	~  
Bx   	=  
CÒ   
GX  	\  
I²    	   
J‘   	=  
KÒ    
O  	\  
Q²    	   
R‘   	®  
Sx   	Ÿ  
T½   	V  
U½    
a¾  	¡   
cÈ    	w  
dÈ    
^İ  <  
e     
g     
Y
  	;   
[È    	1  
]f   	‰  
h¾   
l+  	Ì  
nŠ    	›  
ox    
tX  	X  
vÈ    	l  
wx   	Î   
xM    p
3¹  „  
5¹  V
  
<İ  ¡  
Dş  _rt 
L+  %  
VX    
iİ    
p
  U  
y+   x   É  8    €
$  	  
&x    	N   
(x   	ã  
*x   	Q  
0x   	   
{X     
|É  ’   H$  *  5  x    T  ·    <  !o   i  x   i  È      T  ?  ˜²  	ï  #5   	I  +f  	l   .x   ˆ	„  1³   ²  õ  É  8   @ ¹  '  É  (  É  î  "ò  Ê   ‰  $Ê   ™  2x   à  7x   ¸  ;x   d   [   Á  m   I     Õo  Õ  ×o  .  Ø  :  Ù   $    8    /    8    :  Ÿ  8    r  Ó¸  	,   ÚE    Ÿ  Ò  ã¸  ²  ä¸  (    ˜  	¸  ™Ğ    	ğ   šÊ   	  ›Ê      ¡Ú  W   x   /^  ¨  ~Ÿ  c   )  o  ¿   Ô   q     c  Fx   ‘  dÓ  „      Ñ       œ¨  act fu  ‘Ğ~rc gx   ‘Ì~  ™  E*      Z       œ!sig Ex   ‘l"4  Ei  ‘`"9  EÈ   ‘X  ~   ­  Ã  ×  Ä  U      ñ        4   Ø8   ­   .  í  ²   0  b   %?   N  ¿  'F   int G  )M   ç   Š       ŒŠ   R  Š   ‘  ”Š   ƒ  –Š   Ê   7  Ê   Ş  ØõV  	n   öx    	   ûÄ   	  üÄ   	  ıÄ   	Ô  şÄ    	¶  ÿÄ   (
ª   Ä   0
…   Ä   8
_  Ä   @
  Ä   H
F  Ä   P
  Ä   X
    `
   
”  h
  x   p
]  x   t
¦  –   x
k  F   €
€  T   ‚
"   š  ƒ
O  ª  ˆ
ª  %¡   
X  -Â   ˜
_  .Â    
f  /Â   ¨
m  0Â   °
t  2-   ¸
•  3x   À
{  5°  Ä Ç  š|     	`  ¡   	ç  ¢”  	ÿ  ¦x    ]  Ö   Ê   ª  8     V  Ê   À  8    ¨  u  ?À    @À  u   AÀ  Ñ   é  ‡  ‡”  e  ˆ”  ø  ‰”  è  x   ï  +      è  +  ç  x   ç  +    v  	û
  
¬    	i  ·    Š  	1Š   €	;–  	‡
  	@–    v  ¦  8    <  	F  ¨   â   R  
4ä  	6  
6x    	Ê  
7x    ¿  ä  5  F   ‚  ¯  	İ  ±ï   	i  ²$   ú  Ê   4  8    ú  4   	  ?  ?  I  ë  T  T  ^  é  i  i  s  y	  ~  ~  ˆ  à
  íĞ  	ä  ïï   	`	  ğ+  	à  ñ  	  ôŒ   “  “  Õ  S  ü,  	{
  şï   		  ÿ+  
ù   ü  
q    
Ÿ  ü   à  à  1  Z  <  <  F  C  Q  Q  [  ‘  f  f  p  ­  {  {  …  –	      š  f  ¥  ¥  ¯    º  D  Å  Y  Ğ  n  Û  ƒ  æ  Ğ  ñ  ,  ü  A    V    k    €  (  •  3  ª  >  ï  Y  8   @ I  '  Y  (  Y  
  -Ä   K  .Ä   ?   œ  8    î  "¨  Ä   ğ  $¨  ‰  $Ä   ™  2x   à  7x   ¸  ;x   d   [   Á  m   I     h  ü  á  +  	$  !    ï  wñ  Õ`  Õ  ×`  .  Øp  :  Ù€   æ  p  8    ñ  €  8    ü    8    r  Ó©  	,   Ú6      Ò  ã©  ²  ä©  ‹  Lx   &	  ô  	a  ù   	  ù   Ï  Ï  
  €.@  buf /@   +  0x    €¢	  1M   €;	  2Q  € Ê   Q  8   ÿ (  Q  •  h€9Ü  	¿   :Ï   	
  <Ä  	P  =Q  	ô  ?ÿ  0	  @x   $€1  Ax   (€9  BQ  ,€key CM   0€
  DÜ  4€ Ê   ì  8   1   ˜	  	¸  ™Ê    	ğ   šÄ   	  ›Ä      ¡ì  W   x   /p	  ¨  ~Ÿ  c   )  o  ¿   Ô   q     c  Fx   C  (*Ä	  	n  +Ï   	–  ,Ä	  	Õ
  .C
  	  /Q   key 0M   $ ]  Õ
  @+C
  	n  ,Ï   	’  -…  	<  .Ä   		  /§
   key 0M   4	İ  1Q  8	-  2Q  9	Â
  3Q  :	\
  4Q  ; Ê	  Ä   Y
  8    d  ŸI
  õ   x   P  ¡Š   f  ¦I
  ÷  ®x   R  ¯Š   ¹  x   A  åk  
1  çæ   
@
  ìæ  
{  ğñ  
[  óæ  
ù  ÷æ  
0
  ûæ  
i	  şæ  
ì
  ñ  
û  ñ  

ñ  ñ  
  
æ  
r  æ  
É  æ  
ş  æ   õ	     Ç|    !›  M   R¾     5    Í  {  š  q   µ	  œó  
~  M    
È  ¡M   
±  ¤    ß	  ²ÿ    "  #     Í  @ºÍ  
Â  ¼Í   
o   ¿æ  
J  Â?   	
  Å?   

m  ÉM   
±  Ò  
~  Õx   
È  Úx   
Ô  Şó   
	  áÂ   (

  äÓ  0
²  èx   8
k
  ëÙ  < p  ?   ¾  è  $8      h:…  dev ;‹   	Â  <‘  	`  =  	õ
  >æ  	”  ?æ  	,  @æ  	  A—  	Å  B—  ;vid Cñ  \pid Dñ  ^	Ò	  Eæ  `	%  Fæ  a è  k  |  æ  §  8      6x   %	  8	À !     &P
  :X  	‰ !     &†	  <Ï  	 !     '°  a
       <      œ¤  (œ
  c‘   ‘ ~(7  e¦  ‘à~(  gQ  ‘Ğ~(¼
  hx   ‘€~(S	  iQ  ‘ÿ}(	  jx   ‘„~(š  kx   ‘ˆ~)err lx   ‘Œ~(®	  mQ  ‘ş}*´  sn       +m       «      (Q  }ù  ‘˜~,|       (       ô  (
  x   ‘~(f
  x   ‘”~ ,Á       x       :  (%  ƒÄ	  ‘È~+Á              (Ö  ƒ¤  ‘À~  +#      è      (%  ÖÄ	  ‘°~,#               (Ö  Ö¤  ‘¨~ +i$      Š       -,  ª  ‘¸~    ô  {	  .°
  QÌ      >       œ/
  >Ä	  m      _       œU  0nth >M   ‘L(Q  @ù  ‘P(ß  A8   ‘X+‰      $       (%  DÄ	  ‘h+‰             (Ö  D¤  ‘`   1u  €Q  U             œ2&	  €¤  ‘h  İ   J  Ã    Ä  F%      9        4   Ø8   ­   .  í  ²   0  b   %?   N  ¿  'F   int G  )M   ç       ŒŠ   R  Š   ¯   7  ¯   Ş  Øõ;  	n   öx    	   û©   	  ü©   	  ı©   	Ô  ş©    	¶  ÿ©   (
ª   ©   0
…   ©   8
_  ©   @
  ©   H
F  ©   P
  ©   X
  s  `
   
y  h
  x   p
]  x   t
¦  ‘   x
k  F   €
€  T   ‚
"     ƒ
O    ˆ
ª  %œ   
X  -§   ˜
_  .§    
f  /§   ¨
m  0§   °
t  2-   ¸
•  3x   À
{  5•  Ä Ç  š|   s  	`  ¡s   	ç  ¢y  	ÿ  ¦x    B  »   ¯     8     ;  ¯   ¥  8    ¨  u  ?¥    @¥  u   A¥  ¶   Î  ‡  ‡y  e  ˆy  ø  ‰y  è  x   Ô       è    ç  x   ç    ¨   â   R  4i  	6  6x    	Ê  7x    D  i  5  F   ‚  	¯¤  	İ  	±t   	i  	²©     ¯   ¹  8      ¹   	  Ä  Ä  Î  ë  Ù  Ù  ã  é  î  î  ø  y	        à
  
íU  	ä  
ït   	`	  
ğ°  	à  
ñ—  	  
ô       Z  S  
ü±  	{
  
şt   		  
ÿ°  
ù  
   
q  
  
Ÿ  
   e  e  ¶  Z  Á  Á  Ë  C  Ö  Ö  à  ‘  ë  ë  õ  ­        
  –	        f  *  *  4  ¤  ?  É  J  Ş  U  ó  `    k  U  v  ±    Æ  Œ  Û  —  ğ  ¢    ­    ¸  /  Ã  Ô  Ş  8   @ Î  '  Ş  (  Ş  
  -©   K  .©   ?   !  8    î  "-  ©   ğ  $-  ‰  $©   ™  2x   à  7x   ¸  ;x   d   [   Á  m   I     h  
  á  
°  	$  
!Œ    ï  
wv  
Õå  Õ  
×å  .  
Øõ  :  
Ù   k  õ  8    v    8        8    r  
Ó.  	,   
Ú»      Ò  
ã.  ²  
ä.  (    ˜  	¸  ™¯    	ğ   š©   	  ›©      ¡P  W   x   /Ô  ¨  ~Ÿ  c   )  o  ¿   Ô   q     c  Fx   ®   2  	Q  4Î   	Ñ  7x   	ˆ  8!  val 9x    ß  x   —  .x   	Œ !     €  /x   	 !     µ  1I    l  8    \  s  4l  	`ú      Ä  >x   F%      9      œÙ  >x   ‘\Ş  >-  ‘Pc @x   ‘d    ¡  Dx   ‘`   F   µ  Ã    Ä  (      ı      Ü  .  í  ²   ­   0  b   %-   N  ¿  '4   int G  );   ç       Œ   R     ‘  ”   ƒ  –   º   7  º   G  Å;   4   ØB   I  Æ   	î  "ô   ´   	ğ  $ô   
‰  $´   
™  2m   
à  7m   
¸  ;m   Á   2  &	  b  a  g     g   =  =  Ş  Øõí  n   öm       û´     ü´     ı´   Ô  ş´    ¶  ÿ´   (ª   ´   0…   ´   8_  ´   @  ´   HF  ´   P  ´   X  %  `   
+  h  m   p]  m   t¦  †   xk  4   €€  I   ‚"   1  ƒO  A  ˆª  %‘   X  -²   ˜_  .²    f  /²   ¨m  0²   °t  2Ñ   ¸•  3m   À{  5G  Ä Ç  š|   %  `  ¡%   ç  ¢+  ÿ  ¦m    ô  m  º   A  B     í  º   W  B    ¨  	u  ?W  	  @W  	u   AW  
‡  ‡+  
e  ˆ+  
ø  ‰+  
è  	m   8  ·   ¬  
è  	·  
ç  	m   
ç  	·    
  û
  

œ    i  
§    Š  1   €;"  ‡
  @"      2  B    <  F  ¨   â   R  4p  6  6m    Ê  7m    K  p  ò  ;   Ç    ¨  G  ¶  Ì  ¬  Z  
M         5  4   ‚  ¯÷  İ  ±Ç   i  ²ü   Ò  º     B    s  €¼=  ½  ¾Ç   f  ¿=    ÀB   x º   M  B   u Ò  M   	  X  X  b  ë  m  m  w  é  ‚  ‚  Œ  y	  —  —  ¡  à
  íé  ä  ïÇ   `	  ğ¥  à  ñá    ô¥   ¬  ¬  î  S  üE  {
  şÇ   	  ÿ¥  ù   Ë  q  
	  Ÿ  Ë   ù  ù  J  Z  U  U  _  C  j  j  t  ‘      ‰  ­  ”  ”    –	  ©  ©  ³  f  ¾  ¾  È  ÷  Ó  ]  Ş  r  é  ‡  ô  œ  ÿ  é  
  E    Z     o  +  „  6  ™  A  ®  L  Ã  W  8  r  B   @ b  	'  r  	(  r  

  -´   
K  .´   -   µ  B    d   P   Á  b   I  t   h  Ë  á  ú  $  !Ö    ;   )¥      w  ¿  ¶  Ã  ø  Ô  –  à  C    !:  )Î  ..  /„  2î  32  \  ^P  b"  g$  lÇ  „  ˆì  ‰¬  ÿ     ï  wÀ  ÕÚ  Õ  ×Ú  .  Øê  :  Ùú   µ  ê  B    À  ú  B    Ë  
	  B    r  Ó#	  ,   Ú°    
	  
Ò  ã#	  
²  ä#	    05´	  >  7m    ¸  8m   Â  9m   â  :m   '  ;Ü   X  <M  {  =´    ^  >´	  ( >	  ‹  Lm   Û  aM  1  c  
  €.
  buf /
   +  0m    €¢	  1;   €;	  2-
  € º   -
   B   ÿ (  •  h€9³
  ¿   :=   
  <º	  P  =-
  ô  ?Û	  0	  @m   $€1  Am   (€9  B-
  ,€!key C;   0€
  D³
  4€ º   Ã
  B   1   ˜ô
  ¸  ™º    ğ   š´     ›´    
  ¡Ã
  W   m   /G  "¨  ~"Ÿ  c   )  o  ¿   Ô   q     
c  Fm   #  (m   	” !     
†	  4=  $  #-
  ä7      ˜      œÑ  %B  #Ñ  ‘X&S	  %-
  ‘g&8  &m   ‘h'err 'm   ‘l 4
  $  Ê;   \4      ˆ      œÜ  %B  ÊÑ  ‘¨~%`  Ê;   ‘¤~%„  Ê´   ‘˜~&³  Ì;   ‘´~&¹  Ím   ‘¼~&S	  Î-
  ‘³~&7  Ï2  ‘à~&m  Ğİ  ‘Ğ~&¼
  Ñm   ‘È~'err Òm   ‘Ì~&š  Óm   ‘¸~(Ê4      (       &
  Üm   ‘À~&f
  Üm   ‘Ä~  $Ï  „-
  ÿ2      ]      œ;  %B  „Ñ  ‘X&S	  †-
  ‘g&  ‡m   ‘h'err ˆm   ‘l $ã  KÑ  ì0            œÎ  %B  KÑ  ‘¸~&l  MĞ	  ‘à~&‡  Nm   ‘Ä~&  Oº	  ‘Ì~&  PÑ  ‘Ø~&ù  QB   ‘Ğ~'err Rm   ‘È~ )  1Í/            œM  &Q  6g  ‘P'tmp 6g  ‘X(0      ‰       &%  8Ñ  ‘h(0             &Ö  8M  ‘`   b  *S  g-
  —)      6      œd  +û  i>	  ‘ ,res j´	  ‘€+v  k´	  ‘+  lº	  ‘ø~+  mÑ  ‘˜,i nm   ‘ğ~+ù  oB   ‘ˆ,ret p-
  ‘å~,err qm   ‘ô~-n   Y/      (=+             +f  ¯¬  ‘P+  °4   ‘æ~+ˆ  ºm   ‘è~+ˆ  »m   ‘ü~,a Êm   ‘ì~  .æ  >í(      ª       œ¾  /¢  >Å	  ‘˜/é  >B   ‘+
  W¾  ‘°,err Xm   ‘¬ º   Î  B   - .Û  6Ë(      "       œú  /  6´   ‘h 0v  +Ä(             œ1*  S(      E       œ/N  Sg  ‘h/l  Sg  ‘`  '   o  Ã  £  Ä  |9      ë      T  4   Ø8   ­   .  í  ²   0  N  int ç       Œi   R  i   ‘  ”i   ƒ  –i   ¤   7  ¤   Ş  Øõ0  	n   öb    	   û   	  ü   	  ı   	Ô  ş    	¶  ÿ   (
ª      0
…      8
_     @
     H
F     P
     X
  Ô  `
   
Ú  h
  b   p
]  b   t
¦  p   x
k  F   €
€  T   ‚
"   à  ƒ
O  ğ  ˆ
ª  %{   
X  -œ   ˜
_  .œ    
f  /œ   ¨
m  0œ   °
t  2-   ¸
•  3b   À
{  5ö  Ä â  °   d  (F    O  _  _  8     È   œ  	ù   M    	²   M   	0   œ   	x   œ    Ç  š|   Ô  	`  ¡Ô   	ç  ¢Ú  	ÿ  ¦b    £  °   ¤   ğ  8     œ  ¤     8    ¨  u  ?    @  u   A  «   /  k  .;  ‡  ‡Ú  e  ˆÚ  ø  ‰Ú  è  	b   5  |   q  è  	|  ç  	b   ç  	|  â     
Î  	û
  

†    	i  
‘    ¨   R  4ú  	6  6b    	Ê  7b    Õ  ú  W   b   /M  ¨  ~Ÿ  c   )  o  ¿   Ô   q     c  Fb   M  8	  !       :~  	˜ !     0    =¢  	  !     5  ©  8    ™  ¼  @©  	@û      ß  Ib   	¨ !     B  b   +=      <       œ  f    ‘Xs   ~  ‘h 
  • =      +       œ™  s;      ï      œ—  i  s  ‘Œ~†  t/  ‘€~ap w:  ‘ ~ Ø;      ‘       t ƒb   ‘œ~  \  Z	:            œâ  i  Z  ‘œ~†  [/  ‘~ap ^:  ‘ ~ !©  KÎ  |9             œ¬  M©  ‘P  NÎ  ‘Hret Ob   ‘D  ï   )
  Ã  (  Ä  g=      D        .  í  ²   ­   0  b   %-   N  ¿  '4   int G  );   ç       Œ   R     ¤   7  ¤   «   °   4   ØB   Ş  ØõF  	n   öm    	   û   	  ü   	  ı   	Ô  ş    	¶  ÿ   (
ª      0
…      8
_     @
     H
F     P
     X
  ~  `
   
„  h
  m   p
]  m   t
¦  †   x
k  4   €
€  I   ‚
"   Š  ƒ
O  š  ˆ
ª  %‘   
X  -œ   ˜
_  .œ    
f  /œ   ¨
m  0œ   °
t  2»   ¸
•  3m   À
{  5   Ä Ç  š|   ~  	`  ¡~   	ç  ¢„  	ÿ  ¦m    M  Æ   ¤   š  B     F  ¤   °  B    ¨  u  ?°    @°  u   A°  ‡  ‡„  e  ˆ„  ø  ‰„  è  m   ¶        è    â   ¨   î  ":     ‰  $   ™  2m   à  7m   ¸  ;m   R  	4‘  	6  	6m    	Ê  	7m    l  ‘  ’   
H§  ­  ¸  m    ¶   È  B   @ ¸  '  
È  (  
È  d   P   Á  b   I  t   Õ0  Õ  ×0  .  Ø@  :  ÙP   å  @  B    ğ  P  B    û  `  B    r  Óy  	,   Ú    `  Ò  ãy  ²  äy  (    ˜Ì  	¸  ™¤    	ğ   š   	  ›      ¡›  W   m   /  ¨  ~Ÿ  c   )  o  ¿   Ô   q     c  Fm      :  B    d  Ÿ*  õ   m   P  ¡   f  ¦*  ÷  ®m   R  ¯   Ì  4	À !     Ä  }m   C@      h      œÙ  Ù  }m   ‘\Ş  }:  ‘Pret m   ‘l /  oÆ?      }       œ!    qB   ‘PO  qB   ‘XÜ  qB   ‘` ì  6g=      _      œà    6à  ‘˜O  6à  ‘Ü  6à  ‘ˆG  8æ  ‘_ü  <   ‘¨=  =   ‘°  >   ‘¸  ?   ‘ æ  @B   ‘@Ö  @B   ‘P  @B   ‘H B    ¤   B     ò   ¾  Ã  ¼  Ä  «A      ˆ	      A  4   Ø8   ­   int ²   ç   â   .  í  0  b   %[   N  ¿  'b   G  )F       ŒM   R  M   ¶   7  ¶   ¨   ¶   Ù   	8    
Ş  ØõY  n   ö?       û°     ü°     ı°   Ô  ş°    ¶  ÿ°   (ª   °   0…   °   8_  °   @  °   HF  °   P  °   X  ‘  `   
—  h  ?   p]  ?   t¦  ˜   xk  b   €€  i   ‚"     ƒO  ­  ˆª  %£   X  -®   ˜_  .®    f  /®   ¨m  0®   °t  2-   ¸•  3?   À{  5³  Ä Ç  š
|   ‘  `  ¡‘   ç  ¢—  ÿ  ¦?    `  Ù   ¶   ­  	8     Y  ¶   Ã  	8    ¨  u  ?Ã    @Ã  u   AÃ  ½   ì  ‡  ‡—  e  ˆ—  ø  ‰—  è  ?   ò  .   #  è  .  
R  4c  6  6?    Ê  7?    >  c  ò  ~  	8   @ n  '  	~  (  	~  î  
"§  °   ‰  $°   ™  2?   à  7?   ¸  ;?   d   p   Á  ‚   I     Õ$  Õ  ×$  .  Ø4  :  ÙD   Ù  4  	8    ä  D  	8    ï  T  	8    
r  Óm  ,   Úú    T  Ò  ãm  ²  äm  ‹  L?   
  ˜Ä  ¸  ™¶    ğ   š°     ›°      ¡“  
&	  ô  a  ù     ù   Ï  Ï  
  €.@  buf /@   +  0?    €¢	  1F   €;	  2Q  € ¶   Q  8   ÿ (  •  h€9×  ¿   :Ï   
  <ˆ  P  =Q  ô  ?ÿ  0	  @?   $€1  A?   (€9  BQ  ,€key CF   0€
  D×  4€ ¶   ç  	8   1 
V  e  æ  hF      kF    
Ê  )rU  É  uF    ×  {É   š  ~b   $”  b   &w  ‡[   ( 
C  (*  n  +Ï   –  ,  Õ
  .    /Q   key 0F   $ X  
Õ
  @+  n  ,Ï   ’  -S
  <  .°   	  /u   key 0F   4İ  1Q  8-  2Q  9Â
  3Q  :\
  4Q  ; ¤  °   3  	8    d  Ÿ#  õ   ?   P  ¡M   f  ¦#  ÷  ®?   R  ¯M   A  å9  1  çÙ   @
  ìÙ  {  ğä  [  óÙ  ù  ÷Ù  0
  ûÙ  i	  şÙ  ì
  ä  û  ä  
ñ  ä    
Ù  r  Ù  É  Ù  ş  Ù   õ	    ÇJ    ›  F   RŒ     5    Í  {  š  q   µ	  œÁ  ~  F    È  ¡F   ±  ¤O   ß	  ²Í  Ó  Ş  Ş   ä  Í  @º›	  Â  ¼›	   o   ¿Ù  J  Â[   	  Å[   
m  ÉF   ±  ÒO  ~  Õ?   È  Ú?   Ô  ŞÁ   	  á®   (
  ä¡	  0²  è?   8k
  ë§	  < >  [   Œ  ¶	   8    
  h:S
  dev ;Y
   Â  <_
  `  =Ş  õ
  >Ù  ”  ?Ù  ,  @Ù    Ae
  Å  Be
  ;vid Cä  \pid Dä  ^Ò	  EÙ  `%  FÙ  a ¶	  9  J  Ù  u
  	8    !W   ?   /½
  "¨  ~"Ÿ  c   )  o  ¿   Ô   q     c  F?   #ô  2Ï  	@ !     ¿  4Ï  $P  :8   öJ      =       œ8  %  :ù  ‘X&Q  <ù  ‘`&ß  =8   ‘h '€  8   ˜I      ^      œÖ  %æ  F   ‘L%)   Ö  ‘@(cmd ¡	  ‘¸%
  ¡	  ‘°%µ  8   ‘¨&J  	Ü  ‘`&’  S
  ‘h)ret F   ‘\ ç  U  *W  õ8   I      …       œ   +æ  õF   ‘\,J  ÷Ü  ‘h -&  ï8   I             œ.  èúH             œ*d  ´Ü  |F      ~      œÄ  +  ´F   ‘L+B  ´  ‘@,  ·  ‘h,J  ¹Ü  ‘`/0   0ret Â?   ‘\  *¤  ªF   GF      5       œ  +  ªF   ‘l+Ø  «  ‘`   *ƒ  “8   E      ?      œT  +  “F   ‘\+Ø  ”  ‘P,  –  ‘h -Ÿ  F   öD             œ1g    šD      \       œı  +a  F   ‘L,Q  ù  ‘X,ß  ‚F   ‘T2µD      "       ,  …  ‘h2µD             ,Ö  …ı  ‘`   ô  *<  k  ÀC      Ú       œ  +<  k°   ‘H,Q  mù  ‘P,[  o8   ‘X2ıC      V       ,  t  ‘h2ıC             ,Ö  tı  ‘`   **  [  
C      ¶       œ  +[  [F   ‘L,Q  ]ù  ‘X2"C      Y       ,  `  ‘h2"C             ,Ö  `ı  ‘`   3ï  P­B      ]       œ9  +  P  ‘h *g  DQ  _B      N       œu  +  D°   ‘X0k F8   ‘h 15  6ï  òA      m       œÍ  4key 6°   ‘X4len 6-   ‘P,K  8ï  ‘h0i 8ï  ‘l 5İ  d«A      G       œ+Q  dù  ‘h  æ	   Â  Ã  „  Ä  3K      ·        .  í  ²   ­   0  b   %-   N  ¿  '4   int G  );   ç       Œ   R     ¤   7  ¤   4   ØB   î  "Ç      ğ  $Ç   	‰  $   	™  2m   	à  7m   	¸  ;m   
&	  *  a  *     *     
Ş  Øõ°  n   öm       û     ü     ı   Ô  ş    ¶  ÿ   (ª      0…      8_     @     HF     P     X  è  `   
î  h  m   p]  m   t¦  †   xk  4   €€  I   ‚"   ô  ƒO    ˆª  %‘   X  -œ   ˜_  .œ    f  /œ   ¨m  0œ   °t  2°   ¸•  3m   À{  5
  Ä Ç  š
|   è  `  ¡è   ç  ¢î  ÿ  ¦m    ·  0  ¤     B     °  ¤     B    ¨  u  ?    @  u   A  «   C  	‡  ‡î  	e  ˆî  	ø  ‰î  	è  	m   I  …   z  	è  	…  	ç  	m   	ç  	…  ¨   â   
R  
4Ş  6  
6m    Ê  
7m    ¹  Ş  5  4   
‚  ¯  İ  ±é   i  ²   ô  ¤   .  B    ô  .   	  9  9  C  ë  N  N  X  é  c  c  m  y	  x  x  ‚  
à
  íÊ  ä  ïé   `	  ğÛ  à  ñÂ    ô†       Ï  
S  ü&  {
  şé   	  ÿÛ  ù   ¬  q  @  Ÿ  ¬   Ú  Ú  +  Z  6  6  @  C  K  K  U  ‘  `  `  j  ­  u  u    –	  Š  Š  ”  f  Ÿ  Ÿ  ©    ´  >  ¿  S  Ê  h  Õ  }  à  Ê  ë  &  ö  ;    P    e    z  "    -  ¤  8  I  S  B   @ C  '  S  (  S  	
  -   	K  .   -   –  B    d   P   Á  b   I  t   h  ¬  
á  Û  $  !·    ï  w¡  Õ  Õ  ×  .  Ø   :  Ù0   –     B    ¡  0  B    ¬  @  B    
r  ÓY  ,   Úæ    @  	Ò  ãY  	²  äY  ‹  Lm   
  €.À  buf /À   +  0m    €¢	  1;   €;	  2Ñ  € ¤   Ñ  B   ÿ (  •  h€9W  ¿   :   
  <t  P  =Ñ  ô  ?  0	  @m   $€1  Am   (€9  BÑ  ,€key C;   0€
  DW  4€ ¤   g  B   1 
  ˜˜  ¸  ™¤    ğ   š     ›    	  ¡g  W   m   /ë  ¨  ~Ÿ  c   )  o  ¿   Ô   q     	c  Fm   	†	  -  ²  /;   	¬ !     Ğ  eL      ]       œB	  ë  eB	  ‘h Ø  Á  YIL      D       œt	  B  YB	  ‘h    <B	  ŒK      ½       œ¤	  !  >B	  ‘h "   1;   zK             œ#İ  d3K      G       œQ  d*  ‘h  •   ª  Ã  ö  Ä  êL      ™        4   Ø8   ­   .  í  ²   0  b   %?   N  ¿  'F   int G  )M   ç       ŒŠ   R  Š   ¯   7  ¯   Ş  Øõ;  	n   öx    	   û©   	  ü©   	  ı©   	Ô  ş©    	¶  ÿ©   (
ª   ©   0
…   ©   8
_  ©   @
  ©   H
F  ©   P
  ©   X
  s  `
   
y  h
  x   p
]  x   t
¦  ‘   x
k  F   €
€  T   ‚
"     ƒ
O    ˆ
ª  %œ   
X  -§   ˜
_  .§    
f  /§   ¨
m  0§   °
t  2-   ¸
•  3x   À
{  5•  Ä Ç  š|   s  	`  ¡s   	ç  ¢y  	ÿ  ¦x    B  »   ¯     8     ;  ¯   ¥  8    ¨  u  ?¥    @¥  u   A¥  ¶   Î  ‡  ‡y  e  ˆy  ø  ‰y  è  x   Ô       è    â   ¨   R  4S  	6  6x    	Ê  7x    .  S  Ô  n  8   @ ^  '  	n  (  	n  î  
"—  ©   ‰  $©   ™  2x   à  7x   ¸  ;x   d   [   Á  m   I     Õ  Õ  ×  .  Ø$  :  Ù4   É  $  8    Ô  4  8    ß  D  8    r  Ó]  	,   Úê    D  Ò  ã]  ²  ä]  ‹  Lx   &	  ¨  	a  ­   	  ­   ƒ  ƒ  
  €.ô  buf /ô   +  0x    €¢	  1M   €;	  2  € ¯     8   ÿ (    •  h€9  	¿   :ƒ   	
  <x  	P  =  	ô  ?³  0	  @x   $€1  Ax   (€9  B  ,€key CM   0€
  D  4€ ¯      8   1   ˜Ñ  	¸  ™¯    	ğ   š©   	  ›©      ¡     h:y  dev ;~   	Â  <‰  	`  =F  	õ
  >É  	”  ?É  	,  @É  	  AL  	Å  BL  ;vid CÔ  \pid DÔ  ^	Ò	  EÉ  `	%  FÉ  a õ	  y    „  Í  @ºF  
Â  ¼	   
o   ¿É  
J  Â?   	
  Å?   

m  ÉM   
±  Ò~  
~  Õx   
È  Úx   
Ô  Şğ   
	  á§   (

  ä	  0
²  èx   8
k
  ë	  <   É  \  8    ©   l  8    d  Ÿ\  õ   x   P  ¡Š   f  ¦\  ÷  ®x   R  ¯Š   A  år  
1  çÉ   
@
  ìÉ  
{  ğÔ  
[  óÉ  
ù  ÷É  
0
  ûÉ  
i	  şÉ  
ì
  Ô  
û  Ô  

ñ  Ô  
  
É  
r  É  
É  É  
ş  É     Ç„  ›  M   R»     5    Í  {  š  q   µ	  œğ  
~  M    
È  ¡M   
±  ¤~   ß	  ²ü  	  	   F   r  ?   »  (	  !8    Õ
  @+¡	  	n  ,ƒ   	’  -¡	  	<  .©   		  /®   key 0M   4	İ  1  8	-  2  9	Â
  3  :	\
  4  ; Ü  C  (*ğ	  	n  +ƒ   	–  ,ğ	  	Õ
  .ö	  	  /   key 0M   $   (	  "W   x   /D
  #¨  ~#Ÿ  c   )  o  ¿   Ô   q     c  Fx   P
  3  $µ  4  	° !     $[  ;M   	$ !     $¿  <ƒ  	0 !     %g  úM   T      h       œ'  &”  úM   ‘L'Q  ü­  ‘X'ß  ıM   ‘T(6T      0       )%   '  ‘h(6T             )Ö   -  ‘`   §	  ¨  %}  í'  µS      f       œ±  &B  íğ	  ‘H'Q  ï­  ‘X(ÊS      2       '%  ò'  ‘h(ÊS             'Ö  ò-  ‘`   %
  à'  `S      U       œ/  &[  àM   ‘L'Q  â­  ‘X(tS      "       'J  å'  ‘h(tS             'Ö  å-  ‘`   *å  ¯x   sQ      í      œ­  &æ  ¯M   ‘L'J  ³'  ‘`(×Q            'Ô  ¹x   ‘\()R      Å       '  Ãö	  ‘h   *²  ¡  Q      Z       œİ  &'  ¡x   ‘l *Å  {'  O      ‹      œ‹  &  {ö	  ‘¸&B  {ğ	  ‘°'!  }  ‘O'%  ~'  ‘P'Q  ­  ‘X+ÊO             j  'Ö  „-  ‘` (KP      †       '0  “'  ‘h  *ù  h'  ÂN      Ì       œÕ  &  hö	  ‘X&B  hğ	  ‘P,a j'  ‘h -W  cM   ­N             œ%œ  XM   tN      9       œ0  'Q  Z­  ‘h'ß  [M   ‘d .	  LŞM      –       œª  &”  Lx   ‘L'K  N­  ‘X(öM      c       '%  P'  ‘h(öM             'Ö  P-  ‘`   %5  >M   vM      h       œ6  &”  >x   ‘L'Q  @­  ‘X'ß  AM   ‘T(‘M      0       '%  D'  ‘h(‘M             'Ö  D-  ‘`   /İ  d/M      G       œb  &Q  d­  ‘h 0*  SêL      E       œ&N  S­  ‘h&l  S­  ‘`  £   E  Ã  Ù  Ä  ƒT      j#      ™  4   Ø8   ­   .  í  ²   0  b   %?   N  ¿  'F   int G  )M   ç       ŒŠ   R  Š   ¯   7  ¯   Ş  Øõ;  	n   öx    	   û©   	  ü©   	  ı©   	Ô  ş©    	¶  ÿ©   (
ª   ©   0
…   ©   8
_  ©   @
  ©   H
F  ©   P
  ©   X
  s  `
   
y  h
  x   p
]  x   t
¦  ‘   x
k  F   €
€  T   ‚
"     ƒ
O    ˆ
ª  %œ   
X  -§   ˜
_  .§    
f  /§   ¨
m  0§   °
t  2-   ¸
•  3x   À
{  5•  Ä Ç  š|   s  	`  ¡s   	ç  ¢y  	ÿ  ¦x    B  »   ¯     8     ;  ¯   ¥  8    ¨  u  ?¥    @¥  u   A¥  ¶   Î  ‡  ‡y  e  ˆy  ø  ‰y  è  x   Ô       è    â   ¨   ¯   >  8    ¯   N  8    W   x   /–  ¨  ~Ÿ  c   )  o  ¿   Ô   q     c  Fx   R  	4Æ  	6  	6x    	Ê  	7x    ¡  Æ  Ô  á  8   @ Ñ  '  
á  (  
á  î  "
  ©   ‰  $©   ™  2x   à  7x   ¸  ;x   d   [   Á  m   I     Õ‡  Õ  ×‡  .  Ø—  :  Ù§   <  —  8    G  §  8    R  ·  8    r  ÓĞ  	,   Ú]    ·  Ò  ãĞ  ²  äĞ  ‹  Lx     ˜'  	¸  ™¯    	ğ   š©   	  ›©      ¡ö  &	  W  	a  W   	  W   2  
  €.  buf /   +  0x    €¢	  1M   €;	  2¯  € ¯   ¯  8   ÿ (  •  h€95  	¿   :2   	
  <ë  	P  =¯  	ô  ?]  0	  @x   $€1  Ax   (€9  B¯  ,€key CM   0€
  D5  4€ ¯   E  8   1 V  ej  	æ  hM    	  kM    Ê  )r³  	É  uM    	×  {>  	š  ~F   $	”  F   &	w  ‡?   ( C  (*ü  	n  +2   	–  ,ü  	Õ
  .{  	  /¯   key 0M   $ ¶  Õ
  @+{  	n  ,2   	’  -±
  	<  .©   		  /Ó   key 0M   4	İ  1¯  8	-  2¯  9	Â
  3¯  :	\
  4¯  ;   ©   ‘  8    d  Ÿ  õ   x   P  ¡Š   f  ¦  ÷  ®x   R  ¯Š   A  å—  
1  ç<   
@
  ì<  
{  ğG  
[  ó<  
ù  ÷<  
0
  û<  
i	  ş<  
ì
  G  
û  G  

ñ  G  
  
<  
r  <  
É  <  
ş  <   õ	    Ç¨    ›  M   Rê     5    Í  {  š  q   µ	  œ	  
~  M    
È  ¡M   
±  ¤­   ß	  ²+	  1	   <	  !<	   B	  Í  @ºù	  
Â  ¼ù	   
o   ¿<  
J  Â?   	
  Å?   

m  ÉM   
±  Ò­  
~  Õx   
È  Úx   
Ô  Ş	   
	  á§   (

  äÿ	  0
²  èx   8
k
  ë
  < œ  ?   ê  
  "8      h:±
  dev ;<   	Â  <B  	`  =<	  	õ
  ><  	”  ?<  	,  @<  	  AH  	Å  BH  ;vid CG  \pid DG  ^	Ò	  E<  `	%  F<  a 
  œ  -<  	Õ	  .<   	§  /<  	(  0<  	Ÿ  1<  	Å  2<  	?  3<  	“  4<  	Ğ  5<  	š  6G  	”  7G  
 —  ¨  <  X  8    #°  BM   	´ !     $\  ¹U      4"      œµ  %B  ü  ‘˜x%Š  ©   ‘x%`  ©   ‘ˆx%s  ‚µ  ‘€x%I  ‚M   ‘üw&±  „M   ‘°x'mes …»  ‘€(¡W      `         &k  ®M   ‘ôx (%X      :      L  &S  µj  ‘{&…  ¼M   ‘´x (ËY              &k  ôM   ‘ğx&B  õ¯  ‘¯x&J  ùË  ‘Èz ([      ­       µ  )æ  
M   ‘ìx (à[      G      Æ  )æ  M   ‘¸x))   E  ‘Ğz)
  ÿ	  ‘ˆy*cmd ÿ	  ‘y*buf  ÿ	  ‘°z*p !µ  ‘¨z(:\      ³      M  *id <µ  ‘¸z (_            £  )³  ]M   ‘¼x)`  ]M   ‘àx)¹  ^x   ‘äx)„  _©   ‘Àz +ªa      e      )  ¥x   ‘èx  (>d            ,  )®  º¯   ‘®x)  »¯   ‘­x)  ¼8   ‘øx)O  ¼8   ‘€y)Ü  ¼8   ‘Ğz (Vf      [      °  )S  ëj  ‘àz)ô  íÑ  ‘{)¾  í÷  ‘ø~)[  íÎ  ‘ z*i íx   ‘Àx)™  í©   ‘˜y*key ğM   ‘Üx (Ùh      q      4  )ô  Ñ  ‘{)¾  ÷  ‘ø~)[  Î  ‘z*i x   ‘Äx)™  ©   ‘ y)  x   ‘Ğz)J  Ë  ‘˜z (rk      Ò      ¨  )ô  Ñ  ‘{)¾  ÷  ‘ø~)[  Î  ‘ˆz*i x   ‘Èx)™  ©   ‘¨y)æ  x   ‘Ğz (lm             l  )ô  ,Ñ  ‘{)¾  ,÷  ‘ó~)[  ,Î  ‘ğy*i ,x   ‘Ìx)™  ,©   ‘°y*v .·
  ‘Ğz)ê  /x   ‘€y)J  1Ë  ‘øy+¹n      á      )’  7±
  ‘€z)Q  9.  ‘ø~  (4q      ”      Ğ  )ô  RÑ  ‘{)¾  R÷  ‘ø~)[  RÎ  ‘èy*i Rx   ‘Ğx)™  R©   ‘¸y (ğr      K      T  )ô  ^Ñ  ‘{)¾  ^÷  ‘ø~)[  ^Î  ‘Øy*i ^x   ‘Ôx)™  ^©   ‘Ày)  `x   ‘Ğz)  d{  ‘ày +cu      º      )ô  rÑ  ‘{)¾  r÷  ‘ø~)[  rÎ  ‘Ğy*i rx   ‘Øx)™  r©   ‘Èy  M   ¯   Ë  8   ? ³  ¯   ç  8   8   O ¶   ÷  8    ç  ,õ  NM   ñT      È       œ:  %v  Nx   ‘\&  P8   ‘h -”  EÒT             œf  %æ  EM   ‘l .1  *ƒT      O       œ   /buf *   ‘h/val *x   ‘d <   ¶   Å  Ã  Û  Ä  íw      Ô      ¹   4   Ø8   ­   .  í  ²   0  b   %?   N  ¿  'F   int G  )M   ç       ŒŠ   R  Š   ¯   7  ¯   Ş  Øõ;  	n   öx    	   û©   	  ü©   	  ı©   	Ô  ş©    	¶  ÿ©   (
ª   ©   0
…   ©   8
_  ©   @
  ©   H
F  ©   P
  ©   X
  s  `
   
y  h
  x   p
]  x   t
¦  ‘   x
k  F   €
€  T   ‚
"     ƒ
O    ˆ
ª  %œ   
X  -§   ˜
_  .§    
f  /§   ¨
m  0§   °
t  2-   ¸
•  3x   À
{  5•  Ä Ç  š|   s  	`  ¡s   	ç  ¢y  	ÿ  ¦x    B  »   ¯     8     ;  ¯   ¥  8    ¨  u  ?¥    @¥  u   A¥  ¶   Î  ‡  ‡y  e  ˆy  ø  ‰y  è  x   Ô       è    ç  x   ç    ¨   â   R  4i  	6  6x    	Ê  7x    D  i  5  	F   ‚  
¯¤  	İ  
±t   	i  
²©     ¯   ¹  8      ¹   	  Ä  Ä  Î  ë  Ù  Ù  ã  é  î  î  ø  y	        à
  íU  	ä  ït   	`	  ğµ  	à  ñœ  	  ô       Z  S  ü±  	{
  şt   		  ÿµ  
ù   †  
q    
Ÿ  †   e  e  ¶  Z  Á  Á  Ë  C  Ö  Ö  à  ‘  ë  ë  õ  ­        
  –	        f  *  *  4  ¤  ?  É  J  Ş  U  ó  `    k  U  v  ±    Æ  Œ  Û  —  ğ  ¢    ­    ¸  /  Ã  Ô  Ş  8   @ Î  '  Ş  (  Ş  
  -©   K  .©   ?   !  8    î  "-  ©   ğ  $-  ‰  $©   ™  2x   à  7x   ¸  ;x   d   [   k  Á  m   I     h  †  á  µ  	$  !‘    ï  w{  Õê  Õ  ×ê  .  Øú  :  Ù
   k  ú  8    {  
  8    †    8    r  Ó3  	,   ÚÀ      Ò  ã3  ²  ä3  &	  s  	a  s   	  s   N  (    ˜±  	¸  ™¯    	ğ   š©   	  ›©      ¡€  ©   Ì  8    d  Ÿ¼  õ   x   P  ¡Š   f  ¦¼  ÷  ®x   R  ¯Š   ¹  x   A  åŞ  
1  çk   
@
  ìk  
{  ğ{  
[  ók  
ù  ÷k  
0
  ûk  
i	  şk  
ì
  {  
û  {  

ñ  {  
  
k  
r  k  
É  k  
ş  k   õ	    Çï    ›  M   R1	     5    Í  {  š  q   µ	  œf	  
~  M    
È  ¡M   
±  ¤ô   ß	  ²r	  x	  ƒ	  ƒ	   ‰	  Í  @º@
  
Â  ¼@
   
o   ¿k  
J  Â?   	
  Å?   

m  ÉM   
±  Òô  
~  Õx   
È  Úx   
Ô  Şf	   
	  á§   (

  äF
  0
²  èx   8
k
  ëL
  < ã  ?   1	  [
  8    Õ
  @+Ô
  	n  ,N   	’  -q  	<  .©   		  /   key 0M   4	İ  1y  8	-  2y  9	Â
  3y  :	\
  4y  ;   h:q  dev ;ü   	Â  <  	`  =ƒ	  	õ
  >k  	”  ?k  	,  @k  	  A  	Å  B  ;vid C{  \pid D{  ^	Ò	  Ek  `	%  Fk  a Ô
  œ  -ü  	Õ	  .k   	§  /k  	(  0k  	Ÿ  1k  	Å  2k  	?  3k  	“  4k  	Ğ  5k  	š  6{  	”  7{  
 Ş  ï  k    8    W   x   /`  ¨  ~Ÿ  c   )  o  ¿   Ô   q     c  Fx   :  —x   ¯„            œÛ     —Û  ‘¸!err ™x   ‘L"’  šq  ‘P#]  Ñnˆ      "  ´w  ‘\ [
  ó  Šx   „      ©       œ   ’  Šq  ‘h è  ix   Ã‚      C      œc   ’  iq  ‘X$key iM   ‘T"  kx   ‘l h  Lx   ª            œÂ   ’  Lq  ‘X$key LM   ‘T!res Nx   ‘d"–  Ok  ‘c ›  7x   ı€      ­       œ   ’  7q  ‘X$key 7M   ‘T!res 9x   ‘l   x   º      C      œq   ’  q  ‘X$key M   ‘T!res x   ‘d"–  k  ‘c ¯  x         ­       œÁ   ’  q  ‘X$key M   ‘T!res x   ‘l %×  îx   >~      Ï       œ  &’  îq  ‘X&–  î  ‘P'key îM   ‘L(res ğx   ‘l k  %#  £x   {            œ‰  &’  £q  ‘X'key £M   ‘T&  £‰  ‘H(res ¥x   ‘l)ı  ¦k  ‘k w  *Ä  œÜz      C       œ»  &’  œq  ‘h %  ‡x   z      À       œ  &’  ‡q  ‘h'buf ‡  ‘`&0  ‡x   ‘\ v  %Ã  Wx   <x      à      œƒ  &’  Wq  ‘X'buf W  ‘P&0  Wx   ‘L&ı  Wk  ‘H)U  Yx   ‘l(res Zx   ‘h +1  *íw      O       œ'buf *  ‘h'val *x   ‘d  ¹     Ã  Z  Ä  Áˆ      D       %  4   Ø8   ­   .  ?   í  K   ²   0  b   %?   N  ¿  'K   int G  )W   ç       Œ”   R  ”   ¹   7  ¹   Ş  ØõE  	n   ö‚    	   û³   	  ü³   	  ı³   	Ô  ş³    	¶  ÿ³   (
ª   ³   0
…   ³   8
_  ³   @
  ³   H
F  ³   P
  ³   X
  }  `
   
ƒ  h
  ‚   p
]  ‚   t
¦  ›   x
k  K   €
€  ^   ‚
"   ‰  ƒ
O  ™  ˆ
ª  %¦   
X  -±   ˜
_  .±    
f  /±   ¨
m  0±   °
t  2-   ¸
•  3‚   À
{  5Ÿ  Ä Ç  š|   }  	`  ¡}   	ç  ¢ƒ  	ÿ  ¦‚    L  Å   ¹   ™  8     E  ¹   ¯  8    ¨  u  ?¯    @¯  u   A¯  À   Ø  ‡  ‡ƒ  e  ˆƒ  ø  ‰ƒ  è  ‚   Ş       è    ç  ‚   ç    ¨   â   R  	4s  	6  	6‚    	Ê  	7‚    N  s  5  
K   ‚  ¯®  	İ  ±~   	i  ²³   ‰  ¹   Ã  8    ‰  Ã   	  Î  Î  Ø  ë  ã  ã  í  é  ø  ø    y	        à
  í_  	ä  ï~   	`	  ğ¿  	à  ñ¦  	  ô   "  "  d  S  ü»  	{
  ş~   		  ÿ¿  
ù     
q  $  
Ÿ     o  o  À  Z  Ë  Ë  Õ  C  à  à  ê  ‘  õ  õ  ÿ  ­  
  
    –	      )  f  4  4  >  ®  I  Ó  T  è  _  ı  j    u  _  €  »  ‹  Ğ  –  å  ¡  ú  ¬    ·  $  Â  9  Í  Ş  è  8   @ Ø  '  è  (  è  
  -³   K  .³   ?   +  8    î  "7  ³   ğ  $7  ‰  $³   ™  2‚   à  7‚   ¸  ;‚   d   e   Á  w   €  I  ‰   h    á  ¿  	$  !›    ï  w€  Õô  Õ  ×ô  .  Ø  :  Ù   u    8    €    8      $  8    r  Ó=  	,   ÚÊ    $  Ò  ã=  ²  ä=  &	  }  	a  ‚   	  ‚   X  X  (    ˜À  	¸  ™¹    	ğ   š³   	  ›³      ¡    h:h  dev ;m   	Â  <x  	`  =5	  	õ
  >u  	”  ?u  	,  @u  	  A;	  	Å  B;	  ;vid C€  \pid D€  ^	Ò	  Eu  `	%  Fu  a õ	  h    s  Í  @º5	  
Â  ¼   
o   ¿u  
J  Â?   	
  Å?   

m  ÉW   
±  ÒŠ  
~  Õ‚   
È  Ú‚   
Ô  Şü   
	  á±   (

  ä  0
²  è‚   8
k
  ë%  < ~  u  K	  8    ³   [	  8    d  ŸK	  õ   ‚   P  ¡”   f  ¦K	  ÷  ®‚   R  ¯”   ¹  ‚   F  W    

  ş    •  „  ë  İ  o  ‹  !A  ")!  #Í  )l   *·  0 1  W   F)
  µ  €™    X  W   TZ
      1     ó         W   g»
  Í!   R    ’    µ  W  Û  	g  
û  %  ø  0@  1 A  å  
1  çu   
@
  ìu  
{  ğ€  
[  óu  
ù  ÷u  
0
  ûu  
i	  şu  
ì
  €  
û  €  

ñ  €  
  
u  
r  u  
É  u  
ş  u   Ø     
1  u   
@
  "u  
Ê  (u  
_   1u  
–  4€  
  7u  
Ê   ;u  
„  >u  
m  B  
x  E‚      F   `  (MÄ  
1  Ou   
@
  Tu  
  Wu  
x  Zu  
ê  ^u  
¥  au  
  eu  
q  iu  
Š  lu  
J  pÉ  
m  t  
x  w‚         s  }÷  
   €ü   
™   „‚    Ï  Ä    (ŒŸ  
1  u   
@
  “u  
‰  –€  
|  ™u  
…   œu  
Û  Ÿu  
_   ¢u  
Ã  ¨u  
z  ¬Ÿ  
m  °  
x  ³‚     ÷  <!  †   
æ  ˆ‹   
Ö  ‹‹  
Ó  ‹  
´   ‘‹  rc ”Ø  
  —Ø   ¥  2  «  2    Çs  R   ‚   Š  ì   …!  Â  ~Ó   }Ù  |A  {ğ  z9  y­  x "  w¦  v•!  u?  tş   ›  W   RÇ     5    Í  {  š  q   µ	  œü  
~  W    
È  ¡W   
±  ¤Š   ß	  ²      5	     ?   Ç  4  8      Y  q‚   W   …a  ©!  "   ­  F  Õ
  @+æ  	n  ,X   	’  -æ  	<  .³   		  /»
   key 0W   4	İ  1ˆ  8	-  2ˆ  9	Â
  3ˆ  :	\
  4ˆ  ; Ë   W   ‚   /4  ¨  ~Ÿ  c   )  o  ¿   Ô   q     c  F‚   m  !0  /4  	¸ !     "ô  3X  	@ !     "İ  5:  	Ø !     R   ”  8    „  "K!  9”  	 Ï      #ç!  k‚   ƒ§      ‚      œ9  $Â  k  ‘X%ep ku  ‘T$l  k9  ‘H$0  l‚   ‘P$m  l‚   ‘D&!  n‚   ‘`'ret o‚   ‘d u  #¤  ‚   R¤      1      œ  $!  ‚   ‘¼$Â  x  ‘°$õ
  9  ‘¨$”  9  ‘ $,  9  ‘˜&„  m  ‘X&N  ü  ‘P&U!  É  ‘`&¨     ‘H'ret ‚   ‘@(j¥      ®       &#!  /‚   ‘D    #ô   ò‚   {¢      ×      œ¡  $Â  ò  ‘H$!  ò‚   ‘D&„  ôm  ‘`'ret õ‚   ‘T&  ö  ‘X&  ÷‚   ‘P )  êS¢      (       œ#…  ƒ‚   œ›      ·      œ  'cnt …‚   ‘ˆ~'idx …‚   ‘„~&  …‚   ‘Œ~&˜  †  ‘~&]!  ‡?  ‘¸~&Â  ˆx  ‘˜~&¨  ‰ˆ  ‘‚~&]  Šˆ  ‘ƒ~&  Œ"  ‘à~*<œ      ¹      µ  &	  “»
  ‘À~(|      :      &¿   "  ‘   (¡            &Q  Û‚  ‘ ~(B¡      Ï       &  İ?  ‘°~(B¡             &Ö  İ2  ‘¨~    m  ¹   2  8   ? }  #K  i‚   Nš      N      œy  $  i?  ‘X'err k‚   ‘l +×  ¾‚         G      œ  ,cnt À‚   ‘Ü},err À‚   ‘Ø}!]  Áˆ  ‘Ó}!  Â"  ‘à~,idx Ã‚   ‘Ô}!  Ã‚   ‘ä}!˜  Ä  ‘è}!]!  Å?  ‘¨~!Â  Æx  ‘ğ}!Q  È‚  ‘ø}!   È‚  ‘€~&È  ;X  ‘À~*E            •  !  Ï?  ‘¸~(E             !Ö  Ï2  ‘°~  *Î      i      Û  !	  à»
  ‘À~(‘      f      !¿  î"  ‘   *À–            H  &  @?  ‘ ~*À–             &  &Ö  @2  ‘˜~ ($˜      »       'rc N‚   ‘à}  (6™      ™       &  W?  ‘~(6™             &Ö  W2  ‘ˆ~   +‹  £ˆ  F      Á       œ  -dev £m  ‘è~!Â  ¥x  ‘ğ~!	  ¦»
  ‘€!  ¨"  ‘ (—      U       !  ²?  ‘ø~  +ê  †‚   ƒŒ      Ã       œ:  ,v ˆ:  ‘h    +Ì  t‚   Ù‹      ª       œš  -ctx tš  ‘h-dev tm  ‘`.Ü  ua  ‘\.	  u±   ‘P   /ç   `¹    ‹      Ù       œ  -dev `m  ‘¸.P!  `  ‘°!	  b»
  ‘P!  c‚   ‘L(;‹      P       ,i hW   ‘H  ‹  +,  A8   <Š      Ä       œx  .q  A  ‘X-str A³   ‘P,i B‚   ‘h,len C‚   ‘l 0h!  ‚   Û‰      a       œæ  $Â    ‘h$¿  u  ‘d$j  €  ‘`$l    ‘X$~  ‚   ‘T 1ü  t‰      K       œ   .  t‚  ‘h.¹   t‚  ‘` 2İ  dI‰      G       œL  .Q  d‚  ‘h 2*  S‰      E       œ†  .N  S‚  ‘h.l  S‚  ‘` 3=  @Áˆ      C       œ.N  @‚  ‘h.l  @‚  ‘`  %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   :;  7 I  :;   :;I  :;   :;I  '   I   '  >I:;  (   (   .?:;'I@–B  4 :;I   .:;'@–B  ! :;I  " :;I   %   :;I  $ >  $ >  & I      I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   :;  7 I  :;   :;I  :;   :;I8   :;I8  ! I/  5 I   :;I8  >I:;  (   (   :;    :;I  !>I:;  "'  # I  $! I  %4 G:;  &4 :;I?  '.?:;'@–B  (4 :;I  )4 :;I  *
 :;  +  ,  -4 :;I  .. ?:;'@–B  /.?:;'I@—B  0 :;I  1.:;'I@—B  2 :;I   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I  >I:;  (   (    :;I8  4 :;I  .?:;'I@–B   :;I  4 :;I  U   %  $ >   :;I  $ >      I  & I   :;I  	4 :;I?<  
4 :;I?<  :;   :;I8   :;I8   :;  I  ! I/   <  !   :;  7 I  >I:;  (   (   (   >I:;  :;   :;I  :;  :;   :;I8   :;I8   ! I/  ! :;I8  "(   #4 :;I?  $.?:;'I@–B  % :;I  &4 :;I  '4 :;I  (  ).?:;'@–B  *.?:;'I@–B  +4 :;I  ,4 :;I  -
 :;  ..?:;'@–B  / :;I  0. ?:;'@—B  1.:;'@—B   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   I  I  ! I/   :;   <  4 :;I?<  4 :;I?<  !   7 I  >I:;  (   (   4 G:;  4 :;I  .?:;'I@–B   :;I  . ?:;'@–B  .?:;'@–B   :;I     4 :;I     !.:;'I@–B   %  $ >   :;I  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  '   I  :;   :;I  >I:;  (   (   4 G:;  .?:;'I@–B   :;I  4 :;I  .?:;'@–B  4 :;I   I   %   :;I  $ >  $ >      I  & I  I  	! I/  
:;   :;I8   :;I8   :;   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I  :;   :;I8   :;I8  ! I/   :;I8  :;   :;I  >I:;  (   '   I   ! I  !>I:;  "(   #4 :;I?  $.?:;'I@—B  % :;I  &4 :;I  '.?:;'I@–B  ( :;I  )4 :;I  *.?:;'I@–B  + :;I  ,4 :;I  -. ?:;'I@–B  .. ?:;'@–B  /U  04 :;I  1.?:;'I@—B  2  3.?:;'@–B  4 :;I  5.:;'@—B   %  $ >   :;I  $ >      I  & I  4 :;I?<  	4 :;I?<  
:;   :;I8   :;I8   :;  I  ! I/   <  !   7 I  :;   :;I  :;   :;I8   :;I8  ! I/   :;I8  >I:;  (   (   4 :;I?  .?:;'@–B   :;I   .?:;'I@–B  !4 :;I  ". ?:;'I@–B  #.:;'@—B   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I  :;   :;I8   :;I8  ! I/  5 I   :;I8  :;   :;I  >I:;  (   '    I  !! I  ">I:;  #(   $4 :;I?  %.?:;'I@—B  & :;I  '4 :;I  (  )4 :;I  *.?:;'I@–B  +  ,4 :;I  -. ?:;'I@—B  ..?:;'@–B  /.:;'@—B  0.:;'@—B   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   >I:;  (   (   7 I  :;   :;I  :;   :;I8   :;I8  ! I/   :;I8  :;   :;I  >I:;   '  ! I  "! I  #4 :;I?  $.?:;'@–B  % :;I  &4 :;I  '4 :;I  (  )4 :;I  *4 :;I  +  ,.?:;'I@—B  -.?:;'@—B  ..:;'@—B  / :;I   %   :;I  $ >  $ >      I  & I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I  :;   :;I  >I:;  (   '   I  ! I   :;I8  >I:;  (   .?:;'I@–B    :;I  !4 :;I  "4 :;I  #
 :;  $ :;I  %.?:;'I@–B  & :;I  ' :;I  (4 :;I  )4 :;I  *.:;'@–B  +.:;'@—B   %   :;I  $ >  & I  $ >      I  :;  	 :;I8  
 :;I8   :;  I  ! I/   <  4 :;I?<  4 :;I?<  !   7 I  :;   :;I   :;I8  :;  >I:;  (    :;I8   :;I  (   '   I  ! I  >I:;   >I:;  !4 :;I  "4 :;I?  #.?:;'I@–B  $ :;I  % :;I  &4 :;I  '4 :;I  (  ). ?:;'@–B  *  +.?:;'I@–B  ,4 :;I  - :;I  . :;I  /.:;'I@–B  0.:;'I@–B  1.:;'@–B  2.:;'@—B  3.:;'@—B      ½  û      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/bits/types /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  signal_handler.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   __sigset_t.h   time.h   __sigval_t.h   siginfo_t.h   signal.h   sigaction.h   unistd.h   getopt_core.h   stdint-uintn.h   in.h   common.h    log.h      	*      Å /Ÿ‚v.»[Y£.¬çƒØw×‘Év ¬Y Zä u   R  û      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/bits/types /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  list.h    accept.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   struct_timeval.h   select.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   unistd.h   getopt_core.h   stdint-uintn.h   common.h    sock_info.h    log.h    stlink_connection.h    list_stlink.h    time.h   libusb.h   stlink_mgt.h      	U      €„×».v„Éó‘ h S ¬ÏY5K ¬YYYY¬å´Ÿ  ä [Z"v|(  / ® U p C ¬× ¬]{×¬.ÉÉ‘æ ¬Ê’\Ê \‘ ¬åÊZ[“ ¬Y|/¯ÉMzå ¬&ëwÉ ¬Y	äQØYŸ0¢ ¬¼å ºX œ<±f! W   „  û      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  cmdline.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   unistd.h   getopt_core.h   stdint-uintn.h   common.h    log.h    getopt_ext.h     	F%      >äév&$f_. ¬Ÿ„V°ŸZŸZ ¬Yu[ ¬ º  tƒ º  t ×Z ¬åó ¬åæ0 ¬ º  tƒ º  t ƒ* ] ,XYYYYYY]¡¡]¡Y t   ñ  û      /usr/include/x86_64-linux-gnu/bits /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include /usr/include/x86_64-linux-gnu/bits/types /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  list.h    common.c    types.h   stddef.h   unistd.h   getopt_core.h   libio.h   stdio.h   sys_errlist.h   struct_timeval.h   select.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   stdint-uintn.h   netdb.h   common.h    sock_info.h    socket_type.h   log.h      	(      Ó ½­ôæ»O<PA»/Bòä4g£+½n¬ëƒuv  ¬Y ¬[Yuuuz ¬*çs†Ÿ [‘Y[ ¬]> ¬-ögŸŸ[\ ¬¡Zg#æ 'g¢#Ÿ'g¢#'g¢#»Ÿgy#Ÿ\ ¬Y/ŸYŸ_ ¬Y»Ÿ¡‘uYŸ1Ÿ…/çv ¬ ı~X ò†¬%‘» ¬[ ¬Yu^ƒ ¬\Ÿó ¬Ø»× ¬× y¬ .
Ÿ ¬Y	< æ ­­  ¬,	+‘É‘Ê¡¡'ÉÌ»ŸYæó­Y ¬Ë uä|»Oå ¬X’#gŸh ¬Y’g hgYiƒ¯=-iK5Öçy Ÿ ­®Y(U6Ê¹%ÉÉŸ ’’¡uÉ ¬Ér]‘ ¬Ê¼‘Y¼»>‘uÉ ¬Y½É’u‘ ¬É“ ¬ÉGt Ö= gX»Q  × ä¦œ=;•gŸgY’Ÿ•ƒ…×¯ƒ× ¬'K µ   H  û      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include/x86_64-linux-gnu/bits/types /usr/include /usr/include/x86_64-linux-gnu/sys  log.c    stddef.h   types.h   libio.h   FILE.h   stdarg.h   <built-in>    stdio.h   sys_errlist.h   struct_timeval.h   time.h   log.h      	|9      Ë ‚è=g®7K^X#æÚ-’åx ŠX#æ$-æuEå[’-å>l †LŸØ»?»hu®Y 0   V  û      /usr/include/x86_64-linux-gnu/bits /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  main.c    types.h   stddef.h   libio.h   stdio.h   sys_errlist.h   unistd.h   getopt_core.h   time.h   signal.h   stdint-uintn.h   in.h   common.h    log.h    time.h     	g=      6<å	 ƒƒ†ŸwY®v®vi ¬ ¬®‘‘‘ ¬- ¬ ¬­­­©]­­­ ¬ xX.­­­ ¬ Zp. i‚åuiêiåu[ºæ ¬Z»Z ¬YÉ‘Y¼[ ¬Y_ ¬YZ ¬Yw	t= Î   û  û      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  list.h    stlink_api.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   signal.h   unistd.h   getopt_core.h   stdint-uintn.h   in.h   common.h    sock_info.h    stlink_driver.h    stlink_connection.h    list_stlink.h    time.h   libusb.h   stlink_mgt.h    log.h      	«A      ä „0!­»K<¼ å / ‘  J•‘‘‘=1»$ôvZ1» ¬+½»!1¯Éó ¬,» b ¬Ğ ¬ŸY1¿$Éó ¬&å b ¬Ğ ¬»Y1vvÉóƒ h E ¬ÏY1K»2å×­ ¬"Ÿóóƒ/ ¬7ÉvŸZ3åg„Z1æÙ­ ¬+i J­å ¬8Ÿåg ä y
X ¬ ó»»q‚X ¬Ÿô»»i‚Xu ¬v ¬' ¬Ÿ^$ K1LY@Lu1­×u [ ¬Ÿ»6 Ùv t»òsä tå×¼uôZ•­ô‘)=.„„ É W ¬¡K ù     û      /usr/include/x86_64-linux-gnu/bits /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  list.h    sock_info.c    types.h   stddef.h   unistd.h   getopt_core.h   libio.h   stdio.h   sys_errlist.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   stdint-uintn.h   common.h    sock_info.h    log.h      	3K      ä „0!­»F<K»	.‰×u äv ¬¾Y­×¯K5¼» ¬ » !5» ¬+½¼! …   ï  û      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  list.h    stlink_connection.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   signal.h   unistd.h   getopt_core.h   stdint-uintn.h   in.h   common.h    sock_info.h    stlink_mgt.h    libusb.h   time.h   list_stlink.h    stlink_connection.h    log.h      	êL      Ó ½­ôæ»D„0!­»S<vvÉó ºó G ¬Î=1®Éó ºó ¬$ ~ ¬Ï?Lv É I ¬Ë=1Kå1õ×u»»×ƒ ¬$L ¬$K2óK…0Éó ºY®K z. ¬äMå ¬"gƒu ¬( ¬×»¼K2­ ¬Ÿ’ ¬¼u5­ ¬¡Ø­ŸóL ¬(  ¬&½ ¬óó… ¬¼ô½ ¬Z ¬»¢»¼Y2wÉó» c ¬ÎY1…Éó­ c ¬ÎY1vvÉó ºó G ¬Î=    	  û      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  util.h    stlink_tcp_cmd.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   log.h    time.h   signal.h   unistd.h   getopt_core.h   stdint-uintn.h   in.h   common.h    list.h    sock_info.h    stlink_driver.h    stlink_connection.h    list_stlink.h    time.h   libusb.h   stlink_mgt.h      	ƒT      *­!!!­<u­¡@w“ƒ0ƒ.‘0ƒ"K
.5ç  ‘#æ­u ¬ôèÈš|X!‘#æó ¬%ŞÈ¤|X"‘#æóu ¬-ÒÈ°|X(ó ¬1‘#	º(ç#”ó’Ë¢¢#à|X! ‘#æ
óƒ ¬7ÊŸYŸ0 ¬"ŸjåıÈ…}X"‘#¾ó ¬ÉÊ¡uëÈ—}X( ‘#ŸËÌ"å ä!Ø"[hõ"¡É ¬É ä#®!=®!! ¬\ÉÚg»å "»%,½!&Ÿê‘#ŸÎÉ  ! ¸4ŸyÈ	.  !Ø¾ŸÍÉ.‘ ¬Ë# ä!"ÉÉ ä ä¿ ¬ A Ítµ~X"w’# ¬ ( É   æ É É Ê °Èİ~X# ¬&× ¬+Yœfæ~X# B ~ É ¬&,Ìq>r2 ¬+ ¬& ¬+ Ë Y ƒfÿ~X# B ~ Ë) ¬<æŸ ¬0$ ¬&Ë ¬ + Y í f•X# B ~ Ë) ¬,/‘É ¬- 	Ê 	Y 	Û f§X# B ~ Ì)> Ö .u ¬å ¬&.[ å  ­­ ¼”«K«=s=sKsl5.Ë ¬ + Y 5fMX# B ~ Ê ¬&®É ¬ + Y )fYX# B ~ Ë) ¬&> Öó ¬*#æÊ ¬ + Y fmX# B ~ Ê#*&É ¬ + Y 	fzX ¬å) ¬»Yh" Q   ñ  û      /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet /src/staging/libusb/linux64/include/libusb-1.0  util.h    stlink_mgt.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   unistd.h   getopt_core.h   stdint-uintn.h   list.h    common.h    time.h   libusb.h   list_stlink.h    stlink_mgt.h    log.h      	íw      *­!!!­(<uuvuY¡ÉY£. ¬Yw  h1 ¬Y¼h- ¬Y” ¬­w=2/uY¡ÉYw- ¬YvY2»‘‘@2uY¡»L Ö Ö#ƒL"g„/)=ƒƒ„''# º » K¼zX`åw‚XƒL"g„×åååååƒ„''óôY21uY¡»ƒLógØ ¬'=2çuYw»ƒƒLÉ ¬ =2äèuY¡ƒg„ ¬Ù»= ¬ŸgZƒ ¬Ø =äxçuYw»ƒƒLÉ ¬ =2äèuY¡ƒg„ ¬Ùƒ=gZƒ ¬Ø =äxæuY¡ » ƒõ=g„»ƒƒKó ¬ŸgZv ¬#Z2» ¬É ¬YK ¬óó¼Y2ºæ¼uY[ÉY\ô ¬óM3gY^uŸ×E Ö×E Ö×E Ö×Z Ö×W\­­vƒ… ¬ó¼ Yä A   ç  û      /src/staging/libusb/linux64/include/libusb-1.0 /usr/lib/gcc/x86_64-linux-gnu/7/include /usr/include/x86_64-linux-gnu/bits /usr/include /usr/include/x86_64-linux-gnu/sys /usr/include/netinet  list.h    libusb.h   libusb_mgt.c    stddef.h   types.h   libio.h   stdio.h   sys_errlist.h   time.h   sockaddr.h   socket.h   in.h   signal.h   errno.h   unistd.h   getopt_core.h   stdint-uintn.h   common.h    stlink_mgt.h    time.h   list_stlink.h    log.h      	Áˆ      À ½×¼æ­
<½­ôæ»D„0!­»	<ô/"/œ<Ù:us/¦r.ôÊk ” = J‰k ‘ $ Jk®Y1òéYg‘ ‘ r Jz ¬( Yäygg ¬»vh ¬»Ø Y2…ô¡‘u ¬^ ¬XY2 êZ’Y¯ów½Y]¬æ
t¡/­ ¬,®u ¬$ ¬(g/ v¬ <× ¬Éç2‘ ä :Z- ä 7[2Ê/ ¬É?Y ¬è’ŸuóYó0å“Yv!"(»Y­® ¬E ¬9  ¬åå¾ ¬æY× ¬Y­(Y­ ä>YŸ ¬. ¬æ ¬¯0@ v  tÜ  ­ ¬%$­! ¬,É XY ¬$ ¬9gu0­ ¬( ¬$K‘ o0 Ö<$­ ¬ 0  å / wä Ö< ¬%g]»%) ä YZ ä YZ ä Y0 ¬ %0 ¬ (t.????"=3¬éux ¬Y× ¬Êç2‘ ä :Z- ä 7Z2Ê/ ¬É?Y ¬è‘ŸuóYó0å“Yv!"(»0 ¬DY­ ¬9Z¼ ¬åå” ¬D0@ v  tÇ  É>/­Y ¬$ ¬9g z. <u[K!åAäçƒvô ¬"Yg¼ ¬( ÊY ¬#­g ¬(¼g ¬ =^åøuuvug fó ¬(“ ¬(Ÿ­»ƒ/»h÷ô¾õ” ht J<Ÿ ¬#­Ÿ> ä Y0 ¬ Y0 ¬ Y0 ¬ Yw.???" ¬(x¼=`¬åu(Ÿ ¬Ÿg ¬Y»g ä" ¬(“ƒ ¬&= __off_t _IO_read_ptr _pkey _chain _shortbuf __in6_u size_t si_addr __sigval_t si_errno log_levels __uint8_t sa_flags _IO_2_1_stderr_ _IO_buf_base __sighandler_t _lower long long unsigned int LOG_LVL_STLINK _arch LOG_LVL_DEBUG long long int listen_interface accept_context _fileno _IO_read_end _sigchld __u6_addr16 __u6_addr32 _IO_backup_base si_stime _IO_buf_end _cur_column _upper si_overrun _bounds install_ctrl_handler _old_offset in6addr_loopback GNU C99 7.5.0 -mtune=generic -march=x86-64 -g -g -g -std=gnu99 -std=gnu99 -std=gnu99 -fstack-protector-strong si_addr_lsb si_sigval __uint32_t __off64_t si_pid debug_level LOG_LVL_WARN _IO_marker stdin LOG_LVL_MAX __val si_utime _IO_FILE_plus _IO_write_ptr /src/work/stlinkserver/linux64/src _sbuf short unsigned int si_uid siginfo_t _IO_save_base sival_int LOG_LVL_INFO tz_minuteswest __clock_t _lock _sigsys _flags2 stdout _syscall _IO_2_1_stdin_ _pad optarg _sigpoll optind _sifields _IO_write_end address_family _IO_lock_t in6addr_any _IO_FILE si_tid __environ stderr _pos signal_handler.c _markers _sigfault _Bool unsigned char _addr_bnd __pid_t short int _call_addr LOG_LVL_ERROR LOG_LVL_LIBUSB _vtable_offset _IO_2_1_stdout_ LOG_LVL_OUTPUT si_status optopt __uint16_t tz_dsttime __u6_addr8 opterr __uid_t __sigaction_handler si_signo _IO_read_base _IO_save_end _sys_siglist siginfo sa_sigaction sa_mask __pad0 __pad1 __pad2 __pad3 __pad4 __pad5 _unused2 sa_restorer __sigset_t si_fd _timer LOG_LVL_SILENT sa_handler sival_ptr si_band _IO_write_base si_code sockaddr_ax25 sin6_flowinfo libusb_device_handle interval s_info trace_ep LIBUSB_TRANSFER_ERROR program_invocation_short_name sa_data LIBUSB_TRANSFER_OVERFLOW __fd_mask tx_ep loop sin6_scope_id sockaddr_ns getdate_err databuf LIBUSB_TRANSFER_CANCELLED _sys_nerr bcdDevice idProduct prev __d0 iManufacturer LIBUSB_TRANSFER_COMPLETED read_fd_set sockaddr_ipx __timezone bDeviceClass in_addr_t iProduct bcdUSB sockaddr SOCKET stlk_dev libusb_transfer_status num_iso_packets dev_handle libusb_transfer opened sin_family in_port_t bDeviceSubClass sin6_port timeval sin_zero s_addr data_size sa_family_t libusb_device_descriptor sockaddr_inarp tv_usec sin6_addr LIBUSB_TRANSFER_STALL sockaddr_iso stlink_usb_device non_blocking_accept_main iSerialNumber accept.c sin_addr sockaddr_dl __daylight sockaddr_at socks_in_fd_set user_data list_head total_recd transaction_in_progress socket_error sin_port bMaxPacketSize0 sockaddr_eon connection_list sockaddr_un send_offset b_exit libusb_iso_packet_descriptor fw_major_ver libusb_transfer_cb_fn libusb_device nth_sock data_buffer program_invocation_name bDeviceProtocol bDescriptorType ask_to_kill to_reopen __d1 iso_packet_desc sin6_family fds_bits client_name HEART_BEAT_INTERVAL exit_server ready closed_for_refresh stlink_usb sockaddr_in idVendor rx_ep tv_sec cmdbuf dev_desc LIBUSB_TRANSFER_TIMED_OUT asso total_sent serial stlink_assoc is_socket_listening __tzname timeout is_list_empty __suseconds_t __time_t LIBUSB_TRANSFER_NO_DEVICE restart_after_error actual_length __mptr sa_family _sys_errlist recd_data bNumConfigurations g_listening_sock_nb fw_jtag_ver bLength is_fd_close_recd endpoint sockaddr_in6 trans sockaddr_x25 long_options version_flag cmdline.c help_flag option_index option auto_exit_flag parse_params has_arg argc argv process_accept_event IPPROTO_EGP destroy_listening_sockets common.c ai_addrlen IPPROTO_MTP ai_flags SOCK_RAW IPPROTO_ENCAP ai_next local client_address ai_canonname res1 new_sock IPPROTO_UDP sock_addr SOCK_DCCP SOCK_RDM IPPROTO_IGMP SOCK_SEQPACKET init_sockinfo addr_len __socket_type IPPROTO_IP SOCK_STREAM __ss_align IPPROTO_PIM IPPROTO_GRE IPPROTO_IPV6 __socklen_t create_listening_sockets curr_entry IPPROTO_ICMP IPPROTO_ESP IPPROTO_UDPLITE IPPROTO_MAX IPPROTO_RAW ai_family ai_socktype IPPROTO_RSVP LPSOCKADDR print_address_string hints IPPROTO_DCCP new_sock_info SOCK_NONBLOCK list_add_tail bytes_send IPPROTO_TP new_entry ai_addr expected_size CLEANUP close_socket_env client_address_len timeout_retry SOCK_DGRAM total_received_size IPPROTO_SCTP IPPROTO_PUP IPPROTO_IDP IPPROTO_MPLS non_blocking addrinfo send_data bytes_recd IPPROTO_COMP SOCKADDR_STORAGE psock_info SOCK_CLOEXEC SOCK_PACKET __ss_padding sockaddr_storage p_data_buf IPPROTO_BEETPH get_stlink_tcp_cmd_data IPPROTO_IPIP IPPROTO_TCP process_read_event ai_protocol IPPROTO_AH gp_offset ms_del log_init log_output __builtin_va_list overflow_arg_area handle_log_output_command log_out __gnuc_va_list file reg_save_area format start_delay log_print log.c ms_delay fp_offset log_strings __va_list_tag minor build_ver major get_version_cmd majorStr medium internPtr main_ver minorStr main.c print_version mediumStr tmp_ver rev_ver stlink_close stlink_open_device device_used stlink_get_device_info vendor_id stlink_get_device_info2 stlink_api.c stlink_usb_id enum_unique_id assoc_id delete_stlink_from_list list_to_count stlk_usb stlink_init get_stlink_by_key get_stlink_by_serial_name device_request_2 get_stlink_by_list_index stlink_send_command product_id stlink_get_nb_devices dwTimeOut assoc_list stlink_device_info list_del input_request stlink_usb_list device_id serial_code buffer_size stlink_refresh jenkins_one_at_a_time_hash list_count key_to_find is_item_exist_in_stlink_list sock_info.c alloc_sock_info get_nb_tcp_client sock_info_keys free_sock_info delete_sock_info_from_list del_sock_info make_connection stlink_connection_invalid_usb wanted_client get_usb_number_client assoc_entry new_assoc_index get_nb_client_for_usb get_connection_by_sock usb_key get_tcp_number_client evaluate_auto_kill add_connection connection_count close_connection stlink_connection.c get_connection_by_name already_exists new_connection power_ver size_of_input_cmd prec output_buf usd_dev_id internal_error dev_info_size res1_ver stlink_fw_version tcp_client_api_version bridge_ver res2_ver stlink_tcp_cmd.c connect_id error_convert cmd_answ tcp_cmd_error tcp_server_api_version w_4_uint8_to_buf exclusive_access dev_info process_stlink_tcp_cmd p_answer_size_in_bytes input_buf free_token msc_ver swim_ver g_rwMiscOwner seps stlink_mgt_send_cmd stlink_mgt_get_current_mode stlink_mgt_close_usb stlink_mgt_read_trace_data stlink_mgt_get_version stlink_mgt_open_usb_dbg_if cmdsize error_open stlink_mgt_exit_dfu_mode stlink_mgt_exit_jtag_mode stlink_mgt_dfu_exit stlink_mgt_jtag_exit stlink_mgt_init_buffer stlink_mgt.c stlink_usb_blink_led req_type fwvers result LIBUSB_DT_CONFIG LIBUSB_REQUEST_SYNCH_FRAME LIBUSB_SET_ISOCH_DELAY LIBUSB_REQUEST_GET_CONFIGURATION bAlternateSetting iInterface LIBUSB_DT_STRING LIBUSB_ERROR_INTERRUPTED serial_number LIBUSB_DT_HUB LIBUSB_REQUEST_SET_CONFIGURATION list_move describe bInterval bInterfaceSubClass compute_serial_str LIBUSB_ERROR_NOT_SUPPORTED libusb_mgt.c LIBUSB_REQUEST_GET_INTERFACE LIBUSB_DT_INTERFACE devs LIBUSB_TRANSFER_TYPE_BULK LIBUSB_DT_SS_ENDPOINT_COMPANION libusb_mgt_refresh bNumEndpoints LIBUSB_REQUEST_SET_SEL bInterfaceNumber LIBUSB_TRANSFER_TYPE_BULK_STREAM LIBUSB_DT_REPORT LIBUSB_REQUEST_CLEAR_FEATURE LIBUSB_DT_DEVICE_CAPABILITY LIBUSB_DT_HID LIBUSB_ENDPOINT_OUT LIBUSB_ERROR_OVERFLOW MaxPower hotplug_callback LIBUSB_DT_BOS LIBUSB_DT_ENDPOINT LIBUSB_ERROR_OTHER current_config LIBUSB_TRANSFER_TYPE_CONTROL list_add libusb_descriptor_type b_malloc_err langid bInterfaceProtocol udev wTotalLength wMaxPacketSize bInterfaceClass LIBUSB_REQUEST_SET_DESCRIPTOR micro LIBUSB_ERROR_NO_DEVICE LIBUSB_ERROR_BUSY libusb_mgt_exit_lib errCode LIBUSB_REQUEST_SET_FEATURE LIBUSB_ERROR_TIMEOUT inter_desc libusb_hotplug_callback_handle extra_length libusb_mgt_init_refresh move_entry stlink_found LIBUSB_ENDPOINT_IN usb_delete_list libusb_endpoint_descriptor LIBUSB_TRANSFER_TYPE_INTERRUPT LIBUSB_REQUEST_GET_DESCRIPTOR a_libusb_context LIBUSB_ERROR_NOT_FOUND libusb_transfer_type extra libusb_interface bSynchAddress LIBUSB_REQUEST_SET_ADDRESS libusb_hotplug_event LIBUSB_ERROR_INVALID_PARAM hotplug_handle LIBUSB_SUCCESS LIBUSB_REQUEST_SET_INTERFACE libusb_config_descriptor libusb_endpoint_direction libusb_mgt_real_open libusb_interface_descriptor bNumInterfaces libusb_mgt_remove_device libusb_mgt_claim_interface desc_index bEndpointAddress iConfiguration libusb_mgt_init_lib LIBUSB_DT_DEVICE tmp_entry libusb_standard_request LIBUSB_TRANSFER_TYPE_ISOCHRONOUS libusb_error bmAttributes LIBUSB_DT_SUPERSPEED_HUB bConfigurationValue num_altsetting config_desc nano other_list_entry bRefresh LIBUSB_ERROR_ACCESS stlink_match libusb_mgt_set_configuration transferred if_id ep_id LIBUSB_DT_PHYSICAL libusb_version stlk_pids ep_desc new_stlink libusb_get_string_descriptor LIBUSB_ERROR_IO LIBUSB_ERROR_NO_MEM LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED LIBUSB_REQUEST_GET_STATUS libusb_mgt_bulk_transfer LIBUSB_ERROR_PIPE LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT        Q       d       \                      f                  \      a      ·                                                         8                    T                    t                    ˜                    Ø                    X
                    ˆ                    (                   	 ˜                   
 h                    °                    Ğ                                                             „©                    ©                     Û                    @Ş                    Pú                    Xú                    `ú                    pû                    ı                      !                   ` !                                                                                                                                                                            ñÿ                     P                                 !     à              7     ˆ !            F     Xú              m                    y     Pú              ˜    ñÿ                „    *      Z       ©    ñÿ                ²     U             À    ñÿ                Ê     Œ !            Ô      !            á     `ú      à       î    ñÿ                ÷     (      E          ñÿ                    ˜ !                  !            "    @û      0       ¢    ¨ !            .    |9             7   ñÿ                >   ñÿ                K    «A      G       T   ñÿ                K    3K      G       `   ñÿ                ÷     êL      E       K    /M      G       t   ñÿ                …    ƒT      O       –   ñÿ                …    íw      O       £    Üz      C       º   ñÿ                Ç    Áˆ      C       ÷     ‰      E       K    I‰      G       Ğ    ‰      K       Ú    Û‰      a       ÷    ¸ !                 ‹      Ù           ñÿ                    Ìê                   ñÿ                #     Xú              4    pû              =     Pú              P      Û              c    ı              y    ÀC      Ú       “    €©             £     =      +       ¬                     ¾                     Ğ    Ã‚      C      å    „      ©       ú    úH                 z      À       !    @ !            1    ° !            @                     ^                     j                                          ”                             !             °                     Ä    Ì      >       Ğ    í(      ª       Å                     å    ¬ !            ô    Ø !                                                      2      !            >    tN      9       T    P !             [    Æ?      }       i    ÿ2      ]      |    „      Ñ       ‘    
       <      ª    ­B      ]           „©              Â                     Ö                     ï                                                               7                     J                     ‡                     \    ;      ï      f                     s    _B      N           Í/            ª                     Ä                     ×    Ë(      "       å                                                    G      /                     M                     `     Ï             j    L      ]       …    zK             —                     ´                     Ç    Ù‹      ª       Ø                     ñ    F      Á       
    vM      h                             3                     L                     b    òA      m       }    sQ      í          GF      5       ¦                     Å    <x      à      Ù    O      ‹      è    ‰ !            ô    {                  !                                  /                     C    Ä(             T    ` !            h    ƒŒ      Ã       †                     |                      ‹                     ®    !             »    0 !            Æ                     Ù    g=      _      é    ©             ø    ¹U      4"      	    <Š      Ä       "	                     9	    ä7      ˜      C	                     W	    +=      <       q	    >~      Ï       	    Q      Z        	    ” !            ´	     !            Ä	    ©      e       Ô	    º      C      î	                     
                     
    ŞM      –       4
                     F
    šD      \       _
                     z
                     
    S¢      (       £
    `S      U       º
                     /    à !             Î
    {¢      ×                 +       ë
    
C      ¶       ı
                         ÂN      Ì       &    —)      6      ?    À !            N    ˜I      ^      b    P !             n    ŒK      ½       ¥    C@      h      ~    	:            †    öD             œ    ÒT             §                     ¹                     Ë                     ×                     ã                          ı€      ­                            ,                     C                     V                     j    R¤      1      …                     ›    T      h       ±    ñT      È       ¿    œ›      ·      ×                     ë                                               m      _           \4      ˆ      3                     K    ¯„            f    µS      f       }    |F      ~          I      …           öJ      =       ¨                     ½                     Ï   P !             Û    ì0            ğ                      
          ­           E      ?      [    $ !            6    ƒ§      ‚      O    Nš      N      d                     }                     ‘                     §  "                   İ    °              Ã    ª            Ü    IL      D       ë    F%      9      ø    ´ !                                                      4    I             C    € !            W    ­N             g                      crtstuff.c deregister_tm_clones __do_global_dtors_aux completed.7698 __do_global_dtors_aux_fini_array_entry frame_dummy __frame_dummy_init_array_entry signal_handler.c accept.c is_list_empty cmdline.c help_flag version_flag long_options common.c list_add_tail log.c log_output start_delay log_strings ms_delay main.c stlink_api.c list_del sock_info.c stlink_connection.c stlink_tcp_cmd.c w_4_uint8_to_buf stlink_mgt.c stlink_mgt_init_buffer libusb_mgt.c list_add list_move libusb_get_string_descriptor a_libusb_context stlink_match __FRAME_END__ __init_array_end _DYNAMIC __init_array_start __GNU_EH_FRAME_HDR _GLOBAL_OFFSET_TABLE_ get_stlink_by_serial_name __libc_csu_fini log_init free@@GLIBC_2.2.5 recv@@GLIBC_2.2.5 stlink_usb_blink_led stlink_mgt_close_usb stlink_init stlink_mgt_read_trace_data stlink_usb_list auto_exit_flag __errno_location@@GLIBC_2.2.5 libusb_open strncpy@@GLIBC_2.2.5 strncmp@@GLIBC_2.2.5 _ITM_deregisterTMCloneTable strcpy@@GLIBC_2.2.5 exit_server print_address_string sock_info_keys hotplug_handle sigaction@@GLIBC_2.2.5 setsockopt@@GLIBC_2.2.5 debug_level get_tcp_number_client _edata print_version process_read_event install_ctrl_handler non_blocking_accept_main delete_stlink_from_list strlen@@GLIBC_2.2.5 libusb_release_interface __stack_chk_fail@@GLIBC_2.4 libusb_get_version getopt_long@@GLIBC_2.2.5 htons@@GLIBC_2.2.5 send@@GLIBC_2.2.5 log_print libusb_close is_item_exist_in_stlink_list destroy_listening_sockets gettimeofday@@GLIBC_2.2.5 fputs@@GLIBC_2.2.5 init_sockinfo libusb_get_string_descriptor_ascii memset@@GLIBC_2.2.5 libusb_mgt_refresh libusb_free_config_descriptor ioctl@@GLIBC_2.2.5 stlk_pids delete_sock_info_from_list get_nb_tcp_client libusb_get_config_descriptor close@@GLIBC_2.2.5 hotplug_callback getnameinfo@@GLIBC_2.2.5 libusb_mgt_remove_device get_usb_number_client fputc@@GLIBC_2.2.5 libusb_get_configuration strtok_r@@GLIBC_2.2.5 jenkins_one_at_a_time_hash close_connection stlink_get_device_info2 __libc_start_main@@GLIBC_2.2.5 stlink_mgt_send_cmd add_connection ask_to_kill stlink_mgt_get_version __data_start inet_addr@@GLIBC_2.2.5 signal@@GLIBC_2.2.5 close_socket_env optarg@@GLIBC_2.2.5 libusb_mgt_init_lib __gmon_start__ libusb_hotplug_deregister_callback __dso_handle assoc_list memcpy@@GLIBC_2.14 get_version_cmd _IO_stdin_used process_stlink_tcp_cmd compute_serial_str libusb_get_device_list send_data select@@GLIBC_2.2.5 handle_log_output_command stlink_mgt_get_current_mode evaluate_auto_kill g_listening_sock_nb connection_list __libc_csu_init stlink_mgt_exit_jtag_mode malloc@@GLIBC_2.2.5 fflush@@GLIBC_2.2.5 stlink_connection_invalid_usb libusb_error_name get_stlink_by_list_index __isoc99_sscanf@@GLIBC_2.7 libusb_bulk_transfer libusb_mgt_exit_lib get_connection_by_name listen@@GLIBC_2.2.5 libusb_mgt_set_configuration get_stlink_by_key libusb_set_configuration make_connection create_listening_sockets accept_context stlink_send_command __bss_start alloc_sock_info log_out stlink_get_nb_devices free_token bind@@GLIBC_2.2.5 libusb_get_device libusb_exit libusb_init libusb_get_device_descriptor stlink_mgt_dfu_exit libusb_free_device_list libusb_claim_interface fopen@@GLIBC_2.2.5 strtok@@GLIBC_2.2.5 libusb_mgt_claim_interface vfprintf@@GLIBC_2.2.5 get_nb_client_for_usb error_convert libusb_mgt_init_refresh accept@@GLIBC_2.2.5 strtoul@@GLIBC_2.2.5 atoi@@GLIBC_2.2.5 nth_sock get_stlink_tcp_cmd_data libusb_control_transfer stlink_mgt_open_usb_dbg_if get_connection_by_sock stlink_open_device stlink_close list_count sprintf@@GLIBC_2.2.5 exit@@GLIBC_2.2.5 __TMC_END__ process_accept_event _ITM_registerTMCloneTable stlink_mgt_jtag_exit stlink_get_device_info libusb_mgt_bulk_transfer libusb_mgt_real_open getaddrinfo@@GLIBC_2.2.5 strdup@@GLIBC_2.2.5 strerror@@GLIBC_2.2.5 __cxa_finalize@@GLIBC_2.2.5 stlink_mgt_exit_dfu_mode free_sock_info parse_params g_rwMiscOwner usleep@@GLIBC_2.2.5 freeaddrinfo@@GLIBC_2.2.5 stlink_refresh stderr@@GLIBC_2.2.5 new_assoc_index socket@@GLIBC_2.2.5  .symtab .strtab .shstrtab .interp .note.ABI-tag .note.gnu.build-id .gnu.hash .dynsym .dynstr .gnu.version .gnu.version_r .rela.dyn .rela.plt .init .plt.got .text .fini .rodata .eh_frame_hdr .eh_frame .init_array .fini_array .data.rel.ro .dynamic .data .bss .comment .debug_aranges .debug_info .debug_abbrev .debug_line .debug_str .debug_ranges                                                                                  8      8                                    #             T      T                                     1             t      t      $                              D   öÿÿo       ˜      ˜      @                             N             Ø      Ø      €                          V             X
      X
      /                             ^   ÿÿÿo       ˆ      ˆ                                   k   şÿÿo       (      (      p                            z             ˜      ˜      Ğ                           „      B       h      h      H                                       °      °                                    ‰             Ğ      Ğ      @                            ”                                                                                 bŒ                             £             „©      „©      	                              ©             ©      ©      1                             ±              Û       Û                                   ¿             @Ş      @Ş                                   É             Pú      Pú                                   Õ             Xú      Xú                                   á             `ú      `ú                                    î             pû      pû                                  ˜             ı      ı      X                            ÷               !            P                              ı             ` !     P      €                                    0               P      )                                                  y      @                                                  ¹     O¦                             &                     ©     ı                             4                     Ä     S,                             @     0               Xğ     3"                            K                     ‹     p                                                                "   V                 	                      +     {                                                   ;     Y                                                                                                                                                                                     ./cleanup.sh                                                                                        0000755 0117457 0127674 00000000526 14436403737 012464  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 #!/bin/bash

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