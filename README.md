# Artix_Freshtomato-arm_Samba4

How to build Samba 4.11.x for FreshTomato-arm:
1. Download source of samba-4.11.9 (https://download.samba.org/pub/samba/stable/samba-4.11.9.tar.gz) and extract it into a first folder in your home directory.
2. Download source code of libtirpc-1.2.5 (https://sourceforge.net/projects/libtirpc/files/libtirpc/1.2.5/libtirpc-1.2.5.tar.bz2/download) and extract it into a second folder in your home directory.
3. Download source code of gnutls-3.6.13 (https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.13.tar.xz) and extract it into a third folder in your home directory.
4. Download this repo and extract it into a forth folder in your home directory.
5. Start building a new arm-uClibc-toolchain (according to https://github.com/st-ty1/arm-uClibc-toolchain_buildroot) into a fifth folder of your home directory. Before building make sure, that in uClibc-0.9.32.config-file the option UCLIBC_SUPPORT_AI_ADDRCONFIG is set: "UCLIBC_SUPPORT_AI_ADDRCONFIG=y". After building is complete, make sure that if_pppox.h and ctype.h from the original toolchain is copied into your new arm-toolchain. (All steps needed in README.md of this repo.)
6. Align the paths in shell script "build_ft-arm_samba-4.11" to your five folders in your home directory of step 1.) -5.) and check the paths of to your local FreshTomato repo and -if you are building on Artix/Arch Linux the correct setting ogf the path to the Artix-specific patches. 
7. Start shell script "build_ft-arm_samba-4.11".
 
All files of Samba4, which are copied to the installation directory of Freshtomato (\<path/to/your/FT-arm/repo\>/src-rt-6.x.4708/router/arm-uclibc/install/) have been checked with the FT own libfoo.pl to not contain any unresolved symbol.

Remember that install target in Makefile_samba4.11 is not size-optimized yet (i.e. with modifying libfoo.pl the shared libs of samba4 can be rebuild in a more comprimized form from their corresponding static libs)

BR st-ty1/st_ty/st_ty
