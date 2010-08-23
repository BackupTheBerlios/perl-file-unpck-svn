#! /usr/bin/perl -w
#
# run_cmd.pl - a harness for running unpack commands.

use IPC::Run;
use Data::Dumper;

my $tick = 3;
my $r = run(
  [
    '/bin/sh', '-c', 
    'printenv NUMBER_TWO; sleep 4; echo 44; sleep 3; echo 66'
  ],
  { 
    init => sub { $ENV{NUMBER_TWO} = '22'; print "11\n"; },
    watch => '/tmp/foo', every => 2, debug => 0,
    prog => sub { print "T: $tick$tick\n"; $tick += 2; }
  }
);

die Dumper $r;

#################################
sub run
{
  my ($cmd, $opt) = @_;
  # run the command with 
  # - STDIN closed, unless you specify an { in => ... }
  # - STDERR and STDOUT printed prefixed with 'E: ', 'O: ' to STDOUT, 
  #   unless you specify out =>, err =>, or out_err => ... for both.
  my @run = ($cmd);
  push @run, $opt->{in} ? $opt->{in} : \undef;
  $opt->{out} ||= $opt->{out_err};
  $opt->{err} ||= $opt->{out_err};

  $opt->{out} ||= sub { print "O: @_\n"; };
  $opt->{err} ||= sub { print "E: @_\n"; };

  push @run, $opt->{out};
  push @run, $opt->{err};
  push @run, init => $opt->{init} if $opt->{init};
  push @run, debug => $opt->{debug} if $opt->{debug};

  my $t	= IPC::Run::timer($opt->{every}-0.6) if $opt->{every};
  push @run, $t if $t;

  my $h = IPC::Run::start @run;

  while ($h->pumpable)
    {
      $h->pump;
      if ($t && $t->is_expired)
        {
	  $opt->{prog}->($h, $opt);
	  $t->start($opt->{every});
	}
    }
  return $h->finish;
}
