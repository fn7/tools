#!/usr/local/bin/perl

use strict;
use warnings;

use Path::Class;
use Time::Piece;
use File::Temp qw/tempdir/;
use YAML;

my $dir = $ARGV[0] or die "argument error: \$1 must be specified\n";
my $conf = YAML::LoadFile("$dir/backup.yml");
=cut
---
backupdir: /mnt/works/backup/stage/hogehoge.com
remotedir: hogehoge.com:~/
exclude_pattern: 
  - .*
  - ftpuser
  - system/images
  - local/lib
  - local/var
  - local/man
  - misc/export/archives
=cut


my $BACKUPDIR = $conf->{backupdir};
my $REMOTEDIR = $conf->{remotedir};
my @EXCLUDE_PATTERNS = @{$conf->{exclude_pattern} || []};
my $bar = '='x80;
print <<"EOD";
$bar
\tremote : $REMOTEDIR
\t -> backup : $BACKUPDIR
$bar
EOD
print "backup? [yN]\n";
unless (<STDIN> eq "y\n") {
  print "abort\n";
  exit;
}

=cut
my @EXCLUDE_PATTERNS = qw|
  .*
  ftpuser
  system/images 
  local/lib
  local/var
  local/man
  misc/export
|;
=cut
unless ( -e $BACKUPDIR && -d _) {
   dir($BACKUPDIR)->mkpath;
}
 
# バックアップを作成する
backup();


sub backup{
  chdir $BACKUPDIR;
  unless ( -e "$BACKUPDIR/.git" ) {
     system('git init');
     system('git config user.name fn7');
     system('git config user.email fn7@localhost');
  }
  my $rsync_backup = sprintf q{rsync -e ssh -avh --delete %s %s %s},
    $REMOTEDIR,
    join(' ', map {"--exclude=$_"} @EXCLUDE_PATTERNS),
    $BACKUPDIR;

  system($rsync_backup);
  system('git add .');
  my @git_add;
  my @git_remove;
  open my $git_status, '-|', 'git status -s' or die $!;
  my $ctx = '';
  foreach(<$git_status>) {
    # stageしてない段階なので 'xx'の後ろの値をチェック
    /^\?\?\s(\S+)/o and push @git_add, $1;
    /^(?:\sM)\s(\S+)/o and push @git_add, $1;
    /^(?:\sD)\s(\S+)/o and push @git_remove, $1;
  } 
  close $git_status;
  system(sprintf 'git add %s', join(' ', @git_add)) if @git_add;
  system(sprintf 'git rm %s', join(' ', @git_remove)) if @git_remove;
  system(sprintf 'git commit -m "backup: %s"', (localtime)->strftime('%Y-%m-%d %H:%M:%S'));
}






