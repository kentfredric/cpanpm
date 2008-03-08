use strict;
use warnings;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
my @want_config = qw(gccversion);
my @want_other = qw(REPORT_WRITER REQ:Moose);
# my @want_config = qw(archname usethreads usemymalloc cc byteorder libc gccversion intsize use64bitint archname optimize);
while (<DATA>) {
    my($ok,$id) = /(PASS|FAIL)\s+(\d+)/ or next;
    my $target = "nntp-testers/$id";
    unless (-e $target) {
        $ua->mirror("http://www.nntp.perl.org/group/perl.cpan.testers/$id",$target);
    }
    open my $fh, $target or die;
    my(%extract);
    my $report_writer;
    my $moduleunpack = {};
    my $expect_prereq = 0;
    LINE: while (<$fh>) {
        unless ($extract{REPORT_WRITER}) {
            if (0) {
            } elsif (/created (?:automatically )?by (\S+)/) {
                $extract{REPORT_WRITER} = $1;
            } elsif (/CPANPLUS, version (\S+)/) {
                $extract{REPORT_WRITER} = "CPANPLUS $1";
            } elsif (/This report was machine-generated by CPAN::YACSmoke (\S+)/) {
                $extract{REPORT_WRITER} = "CPAN::YACSmoke $1";
            }
            $extract{REPORT_WRITER} =~ s/\.$// if $extract{REPORT_WRITER};
        }
        for my $want (@want_config) {
            if (/\Q$want\E=(\S+)/) {
                my $cand = $1;
                if ($cand =~ /^'/) {
                    my($cand2) = /\Q$want\E=('(\\'|[^'])*')/;
                    if ($cand2) {
                        $cand = $cand2;
                    } else {
                        die "something wrong in id[$id]want[$want]";
                    }
                }
                $cand =~ s/,$//;
                $extract{$want} = $cand;
            }
        }
        if ($expect_prereq) {
            if (exists $moduleunpack->{type}) {
                my($module,$v);
                if ($moduleunpack->{type} == 1) {
                    (my $leader,$module,undef,$v) = eval { unpack $moduleunpack->{tpl}, $_; };
                    next LINE if $@;
                    if ($leader =~ /^-/) {
                        $moduleunpack = {};
                        $expect_prereq = 0;
                        next LINE;
                    } elsif ($module =~ /^-/) {
                        next LINE;
                    }
                } elsif ($moduleunpack->{type} == 2) {
                    (my $leader,$module,$v) = eval { unpack $moduleunpack->{tpl}, $_; };
                    next LINE if $@;
                    if ($leader =~ /^\*/) {
                        $moduleunpack = {};
                        $expect_prereq = 0;
                        next LINE;
                    }
                }
                $module =~ s/\s+$//;
                $v =~ s/\s+$//;
                $extract{"REQ:$module"} = $v;
            }
            if (/(\s+)(Module\s+) Need Have/) {
                $moduleunpack = {
                                 tpl => 'a'.length($1).'a'.length($2).'a6'.'a*',
                                 type => 1,
                                };
            } elsif (/(\s+)(Module Name\s+)(Have\s+)Want/) {
                $moduleunpack = {
                                 tpl => 'a'.length($1).'a'.length($2).'a'.length($3),
                                 type => 2,
                                };
            }
        }
        if (/PREREQUISITES|Prerequisite modules loaded/) {
            $expect_prereq=1;
        }
    }
    my $diag = "";
    for my $want (@want_other, @want_config) {
        my $have  = $extract{$want} || "[UNDEF]";
        $diag .= "$want\[$have]";
    }
    printf "ok[%s]id[%08d]%s\n", $ok, $id, $diag;
}
__END__
    * FAIL 1128811 5.8.8 patch 33449 on Linux 2.6.22-1-k7 (i686-linux-thread-multi-64int)
    * FAIL 1128741 5.11.0 patch 33450 on Linux 2.6.22-1-k7 (i686-linux-thread-multi)
    * FAIL 1127352 5.10.0 on Linux 2.6.22-3-486 (i686-linux)
    * PASS 1109895 5.8.8 on Openbsd 4.2 (OpenBSD.i386-openbsd-thread-multi-64int)
    * FAIL 1099479 5.10.0 on Solaris 2.9 (sun4-solaris-thread-multi-64int)
    * PASS 1099281 5.8.8 on Darwin 8.10.0 (darwin-thread-multi-64int-2level)
    * FAIL 1095165 5.11.0 patch 33261 on Linux 2.6.22-3-486 (i686-linux-thread-multi)
    * FAIL 1055871 5.10.0 on Linux 2.6.23.1-slh64-smp-32 (x86_64-linux)
    * PASS 1030723 5.8.8 on Linux 2.6.21.5-smp (i686-linux-thread-multi-64int-ld)
    * PASS 1028819 5.10.0 on Linux 2.6.21.5-smp (i686-linux-thread-multi-64int-ld)
    * FAIL 1026136 5.6.2 on Freebsd 6.2-release (amd64-freebsd)
    * PASS 1020799 5.8.8 on Linux 2.6.18-5-alpha-generic (alpha-linux-thread-multi)
    * PASS 1018308 5.11.0 patch 33230 on Linux 2.6.18-5-alpha-generic (alpha-linux-thread-multi)
    * PASS 1015654 5.11.0 patch 33228 on Linux 2.6.16.38 (i686-linux-thread-multi-64int-ld)
    * PASS 1014589 5.8.6 on Linux 2.6.18-4-k7 (i686-linux-thread-multi-64int)
    * PASS 1011311 5.11.0 patch 33163 on Cygwin 1.5.24(0.15642) (cygwin-thread-multi-64int)
    * FAIL 1008978 5.8.8 on Netbsd 4.0 (i386-netbsd-thread-multi-64int)
    * FAIL 1006235 5.11.0 patch 33125 on Netbsd 4.0 (i386-netbsd-thread-multi-64int)
    * PASS 1005539 5.10.0 on Netbsd 2.1.0_stable (alpha-netbsd)
    * FAIL 1001576 5.8.8 on Solaris 2.10 (i86pc-solaris)
    * PASS 987091 5.8.8 on Linux 2.6.15.7 (x86_64-linux-gnu-thread-multi)
    * FAIL 971668 5.8.8 on Linux 2.6.22-14-generic (i686-linux-64int-ld)
    * FAIL 971029 5.10.0 on Linux 2.6.22-14-generic (i686-linux-64int-ld)
    * FAIL 967522 5.10.0 on Linux 2.6.9-34.0.1.elsmp (i686-linux-ld)
    * PASS 965470 5.11.0 patch 32981 on Linux 2.6.18-5-alpha-generic (alpha-linux-thread-multi)
    * FAIL 960382 5.10.0 on Solaris 2.10 (i86pc-solaris-thread-multi-64int)
    * PASS 956554 5.10.0 on Linux 2.6.18-5-alpha-generic (alpha-linux-thread-multi)
    * FAIL 956434 5.10.0 on Netbsd 4.0 (i386-netbsd-thread-multi-64int)
    * FAIL 955257 5.10.0 on Darwin 9.1.0 (darwin-2level)
    * FAIL 954541 5.11.0 patch 32971 on Netbsd 4.0 (i386-netbsd-thread-multi-64int)
    * FAIL 951576 5.10.0 on Linux 2.6.23.1-slh64-smp-32 (x86_64-linux)
    * FAIL 950920 5.10.0 on Netbsd 2.1.0_stable (alpha-netbsd)
    * FAIL 950424 5.10.0 on Solaris 2.9 (sun4-solaris-thread-multi)
    * FAIL 950376 5.10.0 on Freebsd 6.2-release (i386-freebsd-thread-multi)
    * FAIL 950350 5.10.0 on Linux 2.4.27-3-686 (i686-linux-thread-multi)
    * FAIL 950338 5.10.0 on Darwin 8.10.1 (darwin-thread-multi-2level)
    * FAIL 949119 5.10.0 on Openbsd 4.2 (OpenBSD.i386-openbsd-thread-multi-64int)
    * PASS 948921 5.10.0 on Openbsd 4.2 (OpenBSD.i386-openbsd)
    * PASS 948888 5.8.8 on Openbsd 4.2 (OpenBSD.i386-openbsd)
    * PASS 948714 5.10.0 on Solaris 2.9 (sun4-solaris-thread-multi)
    * PASS 948364 5.10.0 on Linux 2.4.27-3-686 (i686-linux-thread-multi)
    * PASS 948142 5.10.0 on Freebsd 6.2-release (i386-freebsd-thread-multi)
    * PASS 948040 5.10.0 on Solaris 2.10 (i86pc-solaris)
    * PASS 948005 5.10.0 on Darwin 8.10.1 (darwin-thread-multi-2level)
    * FAIL 947694 5.10.0 on Linux 2.6.22-1-k7 (i686-linux-64int)
    * FAIL 947448 5.8.8 on Darwin 8.10.0 (darwin-thread-multi-2level)
    * PASS 946614 5.8.8 on Darwin 8.10.0 (darwin-thread-multi-2level)
    * FAIL 946595 5.6.2 on Darwin 8.10.0 (darwin-thread-multi)
    * FAIL 946578 5.10.0 on Darwin 8.10.0 (darwin-thread-multi-64int-2level)
    * PASS 946540 5.8.8 on Linux 2.6.18-53.el5 (i386-linux-thread-multi)
    * PASS 946365 5.10.0 on Netbsd 3.1 (i386-netbsd-thread-multi-64int)
    * FAIL 945015 5.10.0 on Solaris 2.10 (i86pc-solaris)
    * PASS 944980 5.8.8 on Solaris 2.10 (i86pc-solaris)
    * PASS 898396 5.10.0 on Freebsd 6.2-release (i386-freebsd-thread-multi-64int)
    * FAIL 894839 5.8.8 on Freebsd 6.2-release (i386-freebsd-thread-multi-64int)
    * PASS 892654 5.10.0 on Openbsd 4.1 (OpenBSD.i386-openbsd-thread-multi-64int)
    * FAIL 891932 5.10.0 patch 32559 on Freebsd 6.2-release (amd64-freebsd)
    * FAIL 889679 5.10.0 on Linux 2.6.16.38 (i686-linux-thread-multi-64int-ld)
    * FAIL 888155 5.8.8 on Linux 2.6.16.38 (i686-linux-thread-multi-64int-ld)
    * PASS 886411 5.10.0 patch 32468 on Solaris 2.9 (sun4-solaris-thread-multi)
    * PASS 886322 5.9.5 on Freebsd 6.2-release (i386-freebsd)
    * PASS 886307 5.10.0 patch 31856 on Netbsd 2.1.0_stable (alpha-netbsd)
    * PASS 886306 5.10.0 patch 32448 on Linux 2.4.27-3-686 (i686-linux-thread-multi)
    * PASS 886305 5.10.0 patch 32468 on Darwin 8.10.1 (darwin-thread-multi-2level)
    * PASS 886299 5.6.2 on Linux 2.4.27-3-686 (i686-linux)
    * PASS 886296 5.8.8 on Linux 2.4.27-3-686 (i686-linux)
    * PASS 885671 5.8.8 on Linux 2.6.22.10 (x86_64-linux-thread-multi-ld)
    * PASS 885083 5.8.8 on Solaris 2.10 (i86pc-solaris-thread-multi-64int)
    * FAIL 883889 5.8.8 on Linux 2.6.9-42.0.3.elsmp (i386-linux-thread-multi)
    * PASS 882271 5.10.0 on Freebsd 6.2-release (amd64-freebsd-thread-multi)
    * PASS 882232 5.6.2 on Freebsd 6.2-release (amd64-freebsd)
    * FAIL 882136 5.8.8 on Freebsd 6.2-prerelease (amd64-freebsd)
    * NA 882122 5.5.5 on Freebsd 6.2-release (amd64-freebsd)
    * FAIL 881114 5.10.0 on Linux 2.6.22-1-k7 (i686-linux)
    * FAIL 881113 5.11.0 on Linux 2.6.22-1-k7 (i686-linux)
    * FAIL 881111 5.10.0 on Linux 2.6.22-1-k7 (i686-linux-thread-multi)
    * FAIL 881069 5.9.5 on Linux 2.6.22-1-k7 (i686-linux-64int)
    * FAIL 881067 5.6.2 on Linux 2.6.16-2-k7 (i686-linux-64int)
    * FAIL 881066 5.8.6 on Linux 2.6.18-4-k7 (i686-linux-thread-multi-64int)
    * PASS 881063 5.8.7 on Linux 2.6.14 (i686-linux-thread-multi-64int)
    * PASS 881061 5.8.8 patch 32025 on Linux 2.6.22-1-k7 (i686-linux-64int)
    * PASS 880906 5.8.5 on Linux 2.6.18-4-k7 (i686-linux-thread-multi-64int)
