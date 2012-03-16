#!/usr/local/bin/perl

use strict;
use warnings;

use Path::Class;
use Time::Piece;
use File::Temp qw/tempdir/;
use YAML;

my $dir = $ARGV[0];
die "argument error: \$1 must be specified\n" unless $dir;
die "directory not found: $dir\n" unless -e $dir && -f_;
my $yaml = "$dir/backup.yml";
die "config not found: $yaml\n" unless -e $yaml && -f _;
my $conf = YAML::LoadFile( $yaml );
=cut
---
target: hogehoge.com:~/
backup_repository: /mnt/works/backup/stage/hogehoge.com
exclude_pattern: 
  - .*
=cut


my $TARGET = $conf->{target};
$TARGET =~ s/\/$//;
my $GIT_REPOSITORY = $conf->{backup_repository};
my $EXCLUDE_PATTERNS = $conf->{exclude_pattern} || [];

my $username = `whoami`;
my $hostname = `hostname`;
chomp $username;
chomp $hostname;
my $GIT_CONFIG_NAME = $username; 
my $GIT_CONFIG_EMAIL = "${username}\@${hostname}";


my $bar = '='x80;
print <<"EOD";
$bar
\tremote : $TARGET
\t -> backup : $GIT_REPOSITORY
$bar
EOD
print "backup? [yN]\n";
unless (<STDIN> eq "y\n") {
  print "abort\n";
  exit;
}

# バックアップを作成する
my $basename = dir( $GIT_REPOSITORY )->basename;
$basename =~ s/\.git$//;

my $tempdir = tempdir( CLEANUP => 1 );
my $working_directory = "$tempdir/$basename";
my $status_code;
my $cwd = Cwd::cwd;
eval {
  create_repository_if_not_exists( $GIT_REPOSITORY );
  prepare_backup( $tempdir, $GIT_REPOSITORY );
  rsync_backup( $TARGET, $working_directory, $EXCLUDE_PATTERNS );
  commit_and_push_repository( $working_directory, $GIT_CONFIG_NAME, $GIT_CONFIG_EMAIL );
  $status_code = 0;
};
if ($@) {
  warn "ERROR: $@\n";
  $status_code = 1;
}
chdir $cwd;
exit $status_code;


sub create_repository_if_not_exists {
  my ( $repository ) = @_;
  my $cwd = Cwd::cwd;
  unless ( -e $repository && -d _) {
    dir( $repository )->mkpath;
    chdir $repository;
    system('git init --bare');
  }
  chdir $cwd;
}

sub prepare_backup {
  my ( $directory, $repository ) = @_;
  my $cwd = Cwd::cwd;
  chdir $directory;
  system( "git clone $repository" );
  chdir $cwd;
}

sub rsync_backup {
  my ( $target, $directory, $exclude_patterns ) = @_;
  system( sprintf q{rsync -e ssh -avh --delete %s %s %s},
    $target,
    join(' ', map {"--exclude=$_"} @$exclude_patterns),
    $directory,
  );
}

sub commit_and_push_repository {
  my ( $directory, $name, $email ) = @_;
  my $cwd = Cwd::cwd;
  chdir $directory;
  unless ( -e '.git' ) {
    die ".git not found: $directory\n";
  } 
  system( "git config user.name $name" ) if $name;
  system( "git config user.email $email" ) if $email;
  system( 'git add .' );
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

  system( sprintf 'git add %s', join( ' ', @git_add ) ) if @git_add;
  system( sprintf 'git rm %s', join( ' ', @git_remove ) ) if @git_remove;
  system( sprintf 'git commit -m "backup: %s"', (localtime)->strftime('%Y-%m-%d %H:%M:%S') );
  system( 'git push -u origin master' );
  chdir $cwd;
}



