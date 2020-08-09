#!/usr/bin/perl
#
#	libfoo.pl
#	Copyright (C) 2006-2008 Jonathan Zarate
#
#	- strip un-needed objects
#	- create xref of symbols used
#

$root = $ENV{"TARGETDIR"};
$uclibc = $ENV{"TOOLCHAIN"};
$router = $ENV{"SRCBASE"} . "/router";
$openssldir = $ENV{"OPENSSLDIR"};

sub error
{
	print STDERR "\n*** ERROR: " . (shift) . "\n\n";
	exit 1;
}

sub basename
{
	my $fn = shift;
	if ($fn =~ /([^\/]+)$/) {
		return $1;
	}
	return $fn;
}

sub load
{
    my $fname = shift;

	if ((-l $fname) ||
		($fname =~ /\/lib\/modules\/\d+\.\d+\.\d+/) ||
		($fname =~ /\.(asp|gif|png|svg|js|jsx|css|txt|pat|sh)$/)) {
		return;
	}
	
	if (-d $fname) {
		my $d;
		if (opendir($d, $fname)) {
			foreach (readdir($d)) {
				if ($_ !~ /^\./) {
					load($fname . "/" . $_);
				}
			}
			closedir($d);
		}
		return;
	}


	my $f;
	my $base;
	my $ok;
	my $s;

	$base = basename($fname);
	print LOG "\n\nreadelf $base:\n";
	
	open($f, "${uclibc}/bin/arm-brcm-linux-uclibcgnueabi-readelf -WhsdD ${fname} 2>&1 |") || error("readelf - $!\n");

	while (<$f>) {
		print LOG;

		if (/\s+Type:\s+(\w+)/) {
			$elf_type{$base} = $1;
			$ok = 1;
			last;
		}
	}
	
	if (!$ok) {
		close($f);
		return;
	}

	print "$elf_type{$base} $base", " " x 30, "\r";
	
	push(@elfs, $base);
	
	while (<$f>) {
		print LOG;
		
		if (/\(NEEDED\)\s+Shared library: \[(.+)\]/) {
			push(@{$elf_lib{$base}}, $1);
		}
		elsif (/Symbol table for image:/) {
			last;
		}
	}
	
	while (<$f>) {
		print LOG;

		if (/\s+(WEAK|GLOBAL)\s+(?:DEFAULT|VISIBLE)\s+(\w+)\s+(\w+)/) {
			$s = $3;
			if ($2 eq 'UND') {
				if ($1 eq 'GLOBAL') {
					$elf_ext{$base}{$s} = 1;
				}
				else {
					print LOG "*** not GLOBAL\n";
				}
			}
			elsif ($2 eq 'ABS') {
			}
			elsif ($2 =~ /^\d+$/) {
				$elf_exp{$base}{$s} = 1;
			}
			else {
				print LOG "*** unknown type\n";
			}
		}
		elsif (!/Num Buc:/) {
			print LOG "*** strange line\n";
		}
	}

	close($f);
}

sub fixDynDep
{
	my ($user, $dep) = @_;
	
	if (!defined $elf_dyn{$user}{$dep}) {
		push(@{$elf_lib{$user}}, $dep);
		$elf_dyn{$user}{$dep} = 1;

		print LOG "FixDynDep: $user = $dep\n";
	}
}

sub fixDyn
{
	my $s;

	foreach (@elfs) {
		if (/^libipt_.+\.so$/) {
			fixDynDep("iptables", $_);
		}
		elsif (/^libip6t_.+\.so$/) {
			fixDynDep("ip6tables", $_);
		}
		elsif (/^CP\d+\.so$/) {
			fixDynDep("smbd", $_);
		}
	}

	fixDynDep("l2tpd", "cmd.so");
	fixDynDep("l2tpd", "sync-pppd.so");
	fixDynDep("pppd", "pppol2tp.so");
	fixDynDep("pppd", "pptp.so");
	fixDynDep("pppd", "rp-pppoe.so");

#	fixDynDep("libcrypto.so.1.0.0", "libssl.so.1.0.0");
	fixDynDep("libcrypto.so.1.1", "libssl.so.1.1");

#shibby
	fixDynDep("transmission-daemon", "libevent-2.1.so.7");
	fixDynDep("transmission-daemon", "libcurl.so.4");
#	fixDynDep("transmission-daemon", "libiconv.so.2");
	fixDynDep("transmission-remote", "libevent-2.1.so.7");
	fixDynDep("transmission-remote", "libcurl.so.4");
#	fixDynDep("transmission-remote", "libiconv.so.2");
#	fixDynDep("radvd", "libdaemon.so.0.5.0");
	fixDynDep("miniupnpd", "libnfnetlink.so.0");
	fixDynDep("dnscrypt-proxy", "libsodium.so.23");
#	fixDynDep("wlconf", "libshared.so");


#minidlna module, bwq518
	fixDynDep("minidlna", "libz.so.1");
	fixDynDep("minidlna", "libstdc.so.6");
	fixDynDep("minidlna", "libiconv.so.2");
#	fixDynDep("minidlna", "libssl.so.1.0.0");
	fixDynDep("minidlna", "libjpeg.so");
	fixDynDep("minidlna", "libogg.so.0");
	fixDynDep("minidlna", "libvorbis.so.0");
	fixDynDep("minidlna", "libid3tag.so.0");
	fixDynDep("minidlna", "libexif.so.12");
	fixDynDep("minidlna", "libFLAC.so.8");
	fixDynDep("libjpeg.so", "libc.so.0");
	fixDynDep("libavcodec.so.52", "libpthread.so.0");

#ipset modules
	fixDynDep("libipset_iphash.so", "ipset");
	fixDynDep("libipset_iptree.so", "ipset");
	fixDynDep("libipset_ipmap.so", "ipset");
	fixDynDep("libipset_ipporthash.so", "ipset");
	fixDynDep("libipset_ipportiphash.so", "ipset");
	fixDynDep("libipset_ipportnethash.so", "ipset");
	fixDynDep("libipset_iptreemap.so", "ipset");
	fixDynDep("libipset_macipmap.so", "ipset");
	fixDynDep("libipset_nethash.so", "ipset");
	fixDynDep("libipset_portmap.so", "ipset");
	fixDynDep("libipset_setlist.so", "ipset");

	fixDynDep("tomatodata.cgi", "libc.so.0");
	fixDynDep("tomatoups.cgi", "libc.so.0");
	fixDynDep("apcupsd", "libc.so.0");
	fixDynDep("apcupsd", "libgcc_s.so.1");
	fixDynDep("apcaccess", "libc.so.0");
	fixDynDep("smtp", "libc.so.0");
#shibby
	fixDynDep("libbcm.so", "libshared.so");
	fixDynDep("libbcm.so", "libc.so.0");

#!!TB - Updated Broadcom WL driver
	fixDynDep("libbcmcrypto.so", "libc.so.0");
	fixDynDep("nas", "libbcmcrypto.so");
	fixDynDep("wl", "libbcmcrypto.so");
	fixDynDep("nas", "libc.so.0");
	fixDynDep("wl", "libc.so.0");

#Roadkill for NocatSplash
	fixDynDep("splashd","libglib-1.2.so.0.0.10");

#Tomato RAF - php
	fixDynDep("php-cli","libz.so.1.2.11");
	fixDynDep("php-cgi","libz.so.1.2.11");
	fixDynDep("php-cli","libz.so.1");
	fixDynDep("php-cgi","libz.so.1");
}

sub usersOf
{
	my $name = shift;
	my $sym = shift;
	my @x;
	my $e;
	my $l;
	
	@x = ();
	foreach $e (@elfs) {
		foreach $l (@{$elf_lib{$e}}) {
			if ($l eq $name) {
				if ((!defined $sym) || (defined $elf_ext{$e}{$sym})) {
					push(@x, $e);
				}
				last;
			}
		}
	}
	return @x;
}

sub resolve
{
	my $name = shift;
	my $sym = shift;
	my $l;
	
	foreach $l (@{$elf_lib{$name}}) {
#		print "\n$l $sym ", $elf_exp{$l}{$sym}, "\n";
		return $l if (defined $elf_exp{$l}{$sym});
	}
	return "*** unresolved ***";
}

sub fillGaps
{
	my $name;
	my $sym;
	my @users;
	my $u;
	my $t;
	my $found;

	print LOG "Resolving implicit links...\n";
	
	foreach $name (@elfs) {
		foreach $sym (keys %{$elf_ext{$name}}) {
			$found = 0;

			if ($sym eq '__uClibc_start_main') {
				$sym = '__uClibc_main';
			}

			#  __gnu_local_gp is defined specially by the linker on MIPS
			if ($sym eq '__gnu_local_gp') {
				$found = 1;
			}
			elsif (resolve($name, $sym) eq "*** unresolved ***") {
				@users = usersOf($name);
				foreach $u (@users) {
					# if exported by $u
					if (defined $elf_exp{$u}{$sym}) {
						fixDynDep($name, $u);
						$found = 1;
					}
					# if exported by shared libs of $u
					if (($t = resolve($u, $sym)) ne "*** unresolved ***") {
						fixDynDep($name, $t);
						$found = 1;
					}
				}
				
				if ($found == 0) {
					print "Unable to resolve $sym used by $name\n", @users;
					exit 1;
				}
			}
		}
	}
}

sub tab
{
	my $current = shift;
	my $target = shift;
	my $s = "";
	my $n;
	
	while (1) {
		$n = $current + (4 - ($current % 4));
		last if ($n > $target);
		$s = $s . "\t";
		$current = $n;
	}
	while ($current < $target) {
		$s = $s . " ";
		$current++;
	}
	return $s;
}

sub genXref
{
	my $f;
	my $fname;
	my $s;
	my @u;
	
	print "Generating Xref Report...\n";
	
	open($f, ">libfoo_xref.txt");
	foreach $fname (sort keys %elf_type) {
		print $f "$fname:\n";
		
		if (scalar(@{$elf_lib{$fname}}) > 0) {
			print $f "Dependency:\n";
			foreach $s (sort @{$elf_lib{$fname}}) {
				print $f "\t$s", defined $elf_dyn{$fname}{$s} ? " (dyn)\n" : "\n";
			}
		}
		
		if (scalar(keys %{$elf_exp{$fname}}) > 0) {
			print $f "Export:\n";
			foreach $s (sort keys %{$elf_exp{$fname}}) {
				@u = usersOf($fname, $s);
				if (scalar(@u) > 0) {
					print $f "\t$s", tab(length($s) + 4, 40), " > ", join(",", @u), "\n";
				}
				else {
					print $f "\t$s\n";
				}
			}
		}
		
		if (scalar(keys %{$elf_ext{$fname}}) > 0) {
			print $f "External:\n";
			foreach $s (sort keys %{$elf_ext{$fname}}) {
				print $f "\t$s", tab(length($s) + 4, 40), " < ", resolve($fname, $s), "\n";
			}
		}
		
		print $f "\n";
	}
	close($f);
}


sub genSO
{
	my ($so, $arc, $strip, $opt) = @_;
	my $name = basename($so);
	my $sym;
	my $fn;
	my $inuse;
	my @used;
	my @unused;
	my $cmd;
	my $before, $after;

	if (!-f $so) {
		print "$name: not found, skipping...\n";
		return 0;
	}

	#!!TB
	if (!-f $arc) {
		print "$arc: not found, skipping...\n";
		return 0;
	}
	
	foreach $sym (sort keys %{$elf_exp{$name}}) {
		if ((scalar(usersOf($name, $sym)) > 0) || (${strip} eq "no")) {
			push(@used, $sym);
		}
		else {
			push(@unused, $sym);
		}
	}

#	print "\n$name: Attempting to link ", scalar(@used), " and remove ", scalar(@unused), " objects...\n";

	print LOG "\n\n${base}\n";
	
#	$cmd = "mipsel-uclibc-ld -shared -s -z combreloc --warn-common --fatal-warnings ${opt} -soname ${name} -o ${so}";
#	$cmd = "mipsel-uclibc-gcc -shared -nostdlib -Wl,-s,-z,combreloc -Wl,--warn-common -Wl,--fatal-warnings -Wl,--gc-sections ${opt} -Wl,-soname=${name} -o ${so}";
	$cmd = "arm-brcm-linux-uclibcgnueabi-gcc -shared -nostdlib -Wl,-s,-z,combreloc -Wl,--warn-common -Wl,--fatal-warnings -Wl,--gc-sections ${opt} -Wl,-soname=${name} -o ${so}";
	foreach (@{$elf_lib{$name}}) {
		if ((!$elf_dyn{$name}{$_}) && (/^lib(.+)\.so/)) {
			$cmd .= " -l$1";
		}
		else {
#			print LOG "Not marking for linkage: $_\n";
		}
	}
#	print "$cmd -u... ${arc}\n";	
	if (scalar(@used) == 0) {
		print "$name: WARNING: Library is not used by anything, could be deleted...\n";
#		unlink $so;
#		<>;
		return 0;
	}
	$cmd .= " -u " . join(" -u ", @used) . " ". $arc;

	print LOG "Command: $cmd\n";
	print LOG "Used: ", join(",", @used), "\n";
	print LOG "Unused: ", join(",", @unused), "\n";
	
	$before = -s $so;

	system($cmd);
	if ($? != 0) {
		error("ld returned $?");
	}

	$after = -s $so;
	
	print "$name: Attempted to remove ", scalar(@unused), "/", scalar(@unused) + scalar(@used), " symbols. ";
	printf "%.2fK - %.2fK = %.2fK\n", $before / 1024, $after / 1024, ($before - $after) / 1024;
	
#	print "\n$name: Attempting to link ", scalar(@used), " and remove ", scalar(@unused), " objects...\n";
#	printf "Before: %.2fK / After: %.2fK / Removed: %.2fK\n\n", $before / 1024, $after / 1024, ($before - $after) / 1024;
	return ($before > $after)
}


##
##
##

#	print "\nlibfoo.pl - fooify shared libraries\n";
#	print "Copyright (C) 2006-2007 Jonathan Zarate\n\n";

if ((!-d $root) || (!-d $uclibc) || (!-d $router)) {
	print "Missing or invalid environment variables\n";
	exit(1);
}

open(LOG, ">libfoo.debug");
#open(LOG, ">/dev/null");

print "Loading...\r";
load($root);
print "Finished loading files.", " " x 30, "\r";

fixDyn();
fillGaps();

genXref();

$stripshared = "yes";
if ($ARGV[0] eq "--noopt") {
	$stripshared = "no";
}
#genSO("${root}/lib/libc.so.0", "${uclibc}/lib/libc.so.0", "", "-Wl,-init=__uClibc_init");
genSO("${root}/lib/libresolv.so.0", "${uclibc}/arm-brcm-linux-uclibcgnueabi/sysroot/lib/libresolv.so.0", "${stripshared}");
genSO("${root}/lib/libcrypt.so.0", "${uclibc}/lib/libcrypt.so.0", "${stripshared}");
genSO("${root}/lib/libm.so.0", "${uclibc}/lib/libm.so.0");
genSO("${root}/lib/libpthread.so.0", "${uclibc}/lib/libpthread.so.0", "${stripshared}", "-u pthread_mutexattr_init -Wl,-init=__pthread_initialize_minimal_internal");
genSO("${root}/lib/libutil.so.0", "${uclibc}/lib/libutil.so.0", "${stripshared}");
genSO("${root}/lib/libdl.so.0", "${uclibc}/lib/libdl.so.0", "${stripshared}");
genSO("${root}/lib/libnsl.so.0", "${uclibc}/lib/libnsl.so.0", "${stripshared}");

genSO("${root}/usr/lib/libcrypto.so.1.1", "${router}/openssl-1.1/libcrypto.so.1.1");
genSO("${root}/usr/lib/libssl.so.1.1", "${router}/openssl-1.1/libssl.so.1.1", "${stripshared}", "-L${router}/openssl-1.1");

$samba_libs = "-L${router}/samba4/bin/default/source4/heimdal_build -L${router}/samba4/bin/default/lib/util -L${router}/samba4/bin/shared/private -L${router}/samba4/bin/default/lib/talloc -L${router}/samba4/bin/default/source3 -L${router}/samba4/bin/default/lib/tevent -L${router}/samba4/bin/default/libcli/util -L${router}/samba4/bin/default/lib/util -L${router}/gnutls/lib/.libs -L${router}/gmp/.libs -L${router}/samba4/bin/default/lib/tdb -L${router}/samba4/bin/default/librpc -L${router}/samba4/bin/default/lib/ldb -L${router}/samba4/bin/default/source4/dsdb -L${router}/samba4/bin/default/source4/librpc/ -L${router}/samba4/bin/default/lib/param/ -L${router}/samba4/bin/default/auth/credentials/ -L${router}/samba4/bin/default/nsswitch/libwbclient/";

genSO("${root}/usr/lib/libndr-standard.so.0","${router}/samba4/bin/default/librpc/libndr-standard.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libsmbd-base-samba4.so","${router}/samba4/bin/default/source3/libsmbd-base-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libndr-samba4.so","${router}/samba4/bin/default/source4/librpc/libndr-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libndr-samba-samba4.so","${router}/samba4/bin/default/librpc/libndr-samba-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libdcerpc-samba-samba4.so","${router}/samba4/bin/default/librpc/libdcerpc-samba-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libsamba-errors.so.1","${router}/samba4/bin/default/libcli/util/libsamba-errors.so", "", $samba_libs);
genSO("${root}/usr/lib/libasn1-samba4.so.8","${router}/samba4/bin/default/source4/heimdal_build/libasn1-samba4.so.8", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libsmbconf.so.0","${router}/samba4/bin/default/source3/libsmbconf.so.0", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/liblibsmb-samba4.so","${router}/samba4/bin/default/source3/liblibsmb-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libsamba-util.so.0","${router}/samba4/bin/default/lib/util/libsamba-util.so.0", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libnetapi.so.0","${router}/samba4/bin/default/source3/libnetapi.so.0", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libkrb5-samba4.so.26","${router}/samba4/bin/default/source4/heimdal_build/libkrb5-samba4.so.26", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libsmbclient-raw-samba4.so","${router}/samba4/bin/default/source4/libcli/libsmbclient-raw-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libhx509-samba4.so.5","${router}/samba4/bin/default/source4/heimdal_build/libhx509-samba4.so.5", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libsamba-passdb.so.0","${router}/samba4/bin/default/source3/libsamba-passdb.so.0", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libhcrypto-samba4.so.5","${router}/samba4/bin/default/source4/heimdal_build/libhcrypto-samba4.so.5", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libcli-smb-common-samba4.so","${router}/samba4/bin/default/libcli/smb/libcli-smb-common-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libldb.so.2","${router}/samba4/bin/default/lib/ldb/libldb.so.2", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libgssapi-samba4.so.2","${router}/samba4/bin/default/source4/heimdal_build/libgssapi-samba4.so.2", "", $samba_libs);
genSO("${root}/usr/lib/libdcerpc.so.0","${router}/samba4/bin/default/source4/librpc/libdcerpc.so.0", "", $samba_libs);
genSO("${root}/usr/lib/libgensec-samba4.so","${router}/samba4/bin/default/auth/gensec/libgensec-samba4.so", "", $samba_libs);
genSO("${root}/usr/lib/libldbsamba-samba4.so","${router}/samba4/bin/default/lib/ldb-samba/libldbsamba-samba4.so", "", $samba_libs);
genSO("${root}/usr/lib/libsamdb-common-samba4.so","${router}/samba4/bin/default/source4/dsdb/libsamdb-common-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libgse-samba4.so","${router}/samba4/bin/default/source3/libgse-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libsamba-hostconfig.so.0","${router}/samba4/bin/default/lib/param/libsamba-hostconfig.so.0", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libdcerpc-binding.so.0","${router}/samba4/bin/default/librpc/libdcerpc-binding.so.0", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libauth-samba4.so","${router}/samba4/bin/default/source3/auth/libauth-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libwind-samba4.so.0","${router}/samba4/bin/default/source4/heimdal_build/libwind-samba4.so.0", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libmsrpc3-samba4.so","${router}/samba4/bin/default/source3/libmsrpc3-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libsamba-security-samba4.so","${router}/samba4/bin/default/libcli/security/libsamba-security-samba4.so", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libndr-nbt.so.0","${router}/samba4/bin/default/librpc/libndr-nbt.so.0", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libhdb-samba4.so.11","${router}/samba4/bin/default/source4/heimdal_build/libhdb-samba4.so.11", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libndr.so.0","${router}/samba4/bin/default/librpc/libndr.so.0", "${stripshared}", $samba_libs);
genSO("${root}/usr/lib/libsamdb.so.0","${router}/samba4/bin/default/source4/dsdb/libsamdb.so.0", "${stripshared}", $samba_libs);

genSO("${root}/usr/lib/libgnutls.so.30","${router}/gnutls/lib/.libs/libgnutls.so.30", "${stripshared}", "-L${router}/gmp/.libs");
genSO("${root}/usr/lib/mysql/libmysqlclient_r.so.16","${router}/mysql/libmysql_r/.libs/libmysqlclient_r.so.16", "${stripshared}"); # "-L${router}/libncurses/lib"); # libmysqlclient.so.16.0.0: not found,
#genSO("${root}/usr/lib/mysql/libmysqlclient.so.16","${router}/mysql/libmysql/.libs/libmysqlclient.so.16", "${stripshared}", "-L${router}/libncurses/lib");   
genSO("${root}/usr/lib/libtirpc.so.3","${router}/libtirpc/src/.libs/libtirpc.so.3", "${stripshared}");
genSO("${root}/usr/lib/libncurses.so.6","${router}/libncurses/lib/libncurses.so.6", "${stripshared}");
genSO("${root}/usr/lib/libglib-1.2.so.0.0.10","${router}/glib/.libs/libglib-1.2.so.0", "${stripshared}");
genSO("${root}/usr/lib/libiperf.so.0","${router}/iperf/src/.libs/libiperf.so.0", "${stripshared}");
genSO("${root}/usr/lib/libebtc.so.0","${router}/ebtables/.libs/libebtc.so.0", "${stripshared}");
genSO("${root}/usr/lib/libnetfilter_conntrack.so.3","${router}/libnetfilter_conntrack/src/.libs/libnetfilter_conntrack.so.3", "${stripshared}", "-L${router}/libnfnetlink/src/.libs -L${router}/libmnl/src/.libs");
genSO("${root}/usr/lib/libxtables.so.12","${router}/iptables-1.8.x/libxtables/.libs/libxtables.so.12", "${stripshared}", "-L${router}/libnfnetlink/src/.libs");
genSO("${root}/usr/lib/libgmp.so.10","${router}/gmp/.libs/libgmp.so.10", "${stripshared}");
genSO("${root}/usr/lib/libip4tc.so.2","${router}/iptables-1.8.x/libiptc/.libs/libip4tc.so.2", "${stripshared}", "-L${router}/libnfnetlink/src/.libs");
genSO("${root}/usr/lib/libip6tc.so.2","${router}/iptables-1.8.x/libiptc/.libs/libip6tc.so.2", "${stripshared}", "-L${router}/libnfnetlink/src/.libs");
genSO("${root}/usr/lib/libnetfilter_queue.so.1","${router}/libnetfilter_queue/src/.libs/libnetfilter_queue.so.1");   
genSO("${root}/usr/lib/libmnl.so.0","${router}/libmnl/src/.libs/libmnl.so.0");
genSO("${root}/usr/lib/libnetfilter_log.so.1","${router}/libnetfilter_log/src/.libs/libnetfilter_log.so.1");   
genSO("${root}/usr/lib/libmssl.so","${router}/mssl/libmssl.so");
genSO("${root}/usr/lib/libbcm.so","${router}/libbcm/libbcm.so");

genSO("${root}/usr/lib/libz.so.1", "${router}/zlib/libz.so.1");
genSO("${root}/usr/lib/libjpeg.so", "${router}/jpeg/libjpeg.so");
genSO("${root}/usr/lib/libsqlite3.so.0", "${router}/sqlite/.libs/libsqlite3.so.0");
genSO("${root}/usr/lib/liblzo2.so.2", "${router}/lzo/src/.libs/liblzo2.so.2");
genSO("${root}/usr/lib/libshared.so", "${router}/shared/libshared.so");
genSO("${root}/usr/lib/libnvram.so", "${router}/nvram_arm/libnvram.so");
genSO("${root}/usr/lib/libusb-1.0.so.0", "${router}/libusb10/libusb/.libs/libusb-1.0.so.0");

genSO("${root}/usr/lib/libbcmcrypto.so", "${router}/libbcmcrypto/libbcmcrypto.so");

genSO("${root}/usr/lib/libcurl.so.4", "${router}/libcurl/lib/.libs/libcurl.so.4", "", "-L${router}/zlib");
genSO("${root}/usr/lib/libevent-2.1.so.7", "${router}/libevent/staged/usr/local/lib/libevent-2.1.so.7");
genSO("${root}/usr/lib/libiconv.so.2", "${router}/libiconv/lib/.libs/libiconv.so.2");
genSO("${root}/usr/lib/libnfnetlink.so.0", "${router}/libnfnetlink/src/.libs/libnfnetlink.so.0");
genSO("${root}/usr/lib/libsodium.so.23", "${router}/libsodium/src/libsodium/.libs/libsodium.so.23");
genSO("${root}/usr/lib/libpng.so.3", "${router}/libpng/.libs/libpng.so.3");
genSO("${root}/usr/lib/libpng12.so.0", "${router}/libpng/.libs/libpng12.so.0");
genSO("${root}/usr/lib/libxml2.so.2", "${router}/libxml2/.libs/libxml2.so.2");
genSO("${root}/usr/lib/libipset.so.11", "${router}/ipset/lib/.libs/libipset.so.11");
genSO("${root}/usr/lib/libpcre.so.1", "${router}/pcre/.libs/libpcre.so.1");
genSO("${root}/usr/lib/libpcreposix.so.0", "${router}/pcre/.libs/libpcreposix.so.0.0.7");

print "\n";

close(LOG);
exit(0);
