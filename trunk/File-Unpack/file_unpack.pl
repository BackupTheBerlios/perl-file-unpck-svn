#! /usr/bin/perl -w
#
# file_unpack.pl -- Demo of File::Unpack features.
# 
# (C) 2010, jnw@cpan.org, all rights reserved.
# Distribute under the same license as Perl itself.
#
# 2010-06-29, jw -- initial draught
# 2010-08-03, jw -- fixed -v.

use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use FindBin;
use lib "$FindBin::RealBin/blib/lib";
use File::Unpack;

my $version = $File::Unpack::VERSION;
my @exclude;
my $exclude_vcs = 1;
my $help;
my $mime_only;
my @mime_handler_dirs;

my %opt = ( verbose => 1, maxfilesize => '100M', one_shot => 0);

GetOptions(
	"verbose|v+"   => \$opt{verbose},
	"version|V"    => sub { print "$version\n"; exit },
	"quiet"        => sub { $opt{verbose} = 0; },
	"destdir|C=s"  => \$opt{destdir},
	"exclude|E=s"  => \@exclude,
	"exclude-vcs!" => \$exclude_vcs,
	"vcs|include-vcs!" => sub { $exclude_vcs = !$_[1]; },
	"help|?"       => \$help,
	"logfile=s"    => \$opt{logfile},
	"one_shot|1"   => \$opt{one_shot},
	"mimetype|m+"  => \$mime_only,
	"unpack-include-dir|I|u=s" => \@mime_handler_dirs,
	"maxfilesize=s"=> \$opt{maxfilesize},
) or $help++;

@mime_handler_dirs = split(/,/,join(',',@mime_handler_dirs));
my $archive = shift or $help++;

pod2usage(-verbose => 1, -msg => qq{
file_unpack V$version Usage: 

$0 [options] input.tar.gz
$0 [options] input/

Valid options are:
 -v	Be more verbose. Default: $opt{verbose}.
 -q     Be quiet, not verbose.

 -C --destdir dir
        Directory, where to place the output file or directory.
	A subdirectory is created, if there are more than one files to unpack.
	Default: current dir.

 -E --exclude glob.pat
 	Specify files and directories that are not unpacked.
	This option can be specified multiple times.

 --exclude-vcs	--no-exclude-vcs 
 --include-vcs  --no-include-vcs --vcs --no-vcs
 	Group switch for directory glob patterns of most version control systems.
	This affects at least SCCS, RCS, CVS, .svn, .git, .hg, .osc .
        Default: exclude-vcs=$exclude_vcs.

 -1 --one-shot
 	Make unpacker non-agressive. Perform one level of unpacking only.

 -h --help -?
        Print this online help.
 
 -l --logfile  file.log
 	Specify a logfile, where freshly unpacked files are reported.
	The format of the logfile is JSON; default is STDOUT.

 --maxfilesize size
        Truncate an unpacked file, if it gets larger than the specified size.
	Size can be specified as bytes (plain integer), kilo-, mega-, giga-, or 
	tera-bytes (suffix K,M,G,T). Default: $opt{maxfilesize}.

 -m --mimetype
        Do not unpack, just report mimetype of the archive, and which unpacker would be used.

 -u --use-mime-handler-dir dir
 	Include an additonal directory of mime handlers.
	Useable multiple times. Later additions take precedence.

}) if $help;


if ($mime_only)
  {
    my $u = File::Unpack->new(logfile => '/dev/null');
    my $m = $u->mime($archive);
    $u->mime_handler_dir(@mime_handler_dirs);
    my ($h,$r) = $u->find_mime_handler($m);
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    print Dumper $m;
    print File::Unpack::fmt_run_shellcmd($h) . "\n";
    exit 0;
  }

my $u = File::Unpack->new(%opt);
$u->exclude(vcs => $exclude_vcs);
$u->exclude(add => \@exclude) if @exclude;
$u->mime_handler_dir(@mime_handler_dirs);
$u->unpack($archive);

#delete $u->{json};
#die "$0: " . Dumper $u;
