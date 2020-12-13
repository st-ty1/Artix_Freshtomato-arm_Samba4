# Artix_Freshtomato-arm_Samba4

How to build Samba 4.11.x for FreshTomato-arm:
1. Download source of samba-4.11.9 (https://download.samba.org/pub/samba/stable/samba-4.11.9.tar.gz) and extract it into a first folder in your home directory.
2. Download source code of libtirpc-1.2.5 (https://sourceforge.net/projects/libtirpc/files/libtirpc/1.2.5/libtirpc-1.2.5.tar.bz2/download) and extract it into a second folder in your home directory.
3. Download source code of gnutls-3.6.13 (https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.13.tar.xz) and extract it into a third folder in your home directory.
4. Download this repo and extract it into a forth folder in your home directory.
5. Start building a new arm-uClibc-toolchain (according to https://github.com/st-ty1/arm-uClibc-toolchain_buildroot) into a fifth folder of your home directory. Before building make sure, that in uClibc-0.9.32.config-file the option UCLIBC_SUPPORT_AI_ADDRCONFIG is set: "UCLIBC_SUPPORT_AI_ADDRCONFIG=y". After building is complete, make sure that if_pppox.h and ctype.h from the original toolchain is copied into your new arm-toolchain. (All steps needed in README.md of this repo.)
6. Align the paths in shell script "build_ft-arm_samba-4.11" to your five folders in your home directory of step 1.) -5.) and check the paths of to your local FreshTomato repo and -if you are building on Artix/Arch Linux the correct setting ogf the path to the Artix-specific patches. 
7. Start shell script "build_ft-arm_samba-4.11".
 
Rem.: To get the libfoo.pl script included in FT-arm repo working, following step are necessary: (all needed files are included in this repo and recognized by shell script "build_ft-arm_samba-4.11")
1. The patch "0101-Create-short-Makefiles-for-Debian.patch" has to be amended. Reason: The arm-toolchain still contains an old libcrypto.so-library based on openssl-1.0.2u (located in /release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib/). This is an odd residue form the building process of the arm-toolchain by the buildroot method. Actually, openssl-1.1 is used by FT-arm. Only mkfs.hfs and fsck.hfs of diskdev-cmd are still linked to the old libcrypto.so instead of newer openssl-1.1 based libcrypto.so, and libfoo.pl will break. To avoid this two of the Makefiles within diskdev_cmd folder have to be directed to the newer oppenssl-1.1 based version of libcrypto.so.
2. Many of the "\*-install" targets in /release/src-rt-6.x.4708/router/Makefile, which copy their built shared libraries and some symlinks to them to $INSTALLDIR, have to be corrected to such extent, that they copy only theirlibs with their soname to $(INSTALLDIR). (done by "Makefile_libfoo.patch") 
3. The library filenames have also to be amended in genSO-subroutine calls of the main part of libfoo.pl to their sonames. 
4. The filename of the arm-version of readelf is wrong and must be corrected. 
5. The exit command in subroutine fillGaps can be reactivated (was commented before), as for now the fillGaps subroutine works correctly without error.

Amendments 3. -5. are included in libfoo_arm2.pl (in this repo). The Makefile in /release/src-rt-6.x.4708/router/ also has to be amended (included in "Makefile_libfoo.patch"), that libfoo.pl can be used without the --noopt option.

actual size for ac68z (RT-AC56U; AIO-version): ~22.7 MB

BR st-ty1/st_ty/st_ty
