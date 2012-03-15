#!/usr/local/bin/perl
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

my $block_id = $ARGV[0];
my $iter = Unicode::Block->new;
my $res = ( $block_id ) 
  ? print_characters( $block_id )
  : print_index();

exit $res;


sub print_index {
  my $n = 1;
  while( my $r = $iter->next ) {
    my ($name_ja) = @$r;
    printf "%2d | %s \n", $n++, $name_ja;
  }
  return 1;
}

sub print_characters {
  my $id = shift;
  my $n = 1;
  my $r;
  while ( $r = $iter->next ){
    last if ( $n++ == $block_id );
  }
  unless ( $r ) {
    print "none selected\n";
    return 0; 
  }
  my (undef, undef, $start, $end ) = @{$r || []};
  for( my $i = $start; $i < $end; $i++) {
    print chr( $i );
  } 
  print "\n";
  return 1;
}



package Unicode::Block;
sub new {
  bless {}, shift;
}

sub next {
  my $line = <DATA>;
  return undef unless ($line and length $line);
  my ($name_ja, $name_en, $start, $end) = map {s/^\s+|\s+$//go;$_} split(/\|/, $line); 
  $start = hex( $start );
  $end = hex( $end );
  return [$name_ja, $name_en, $start, $end]
}

__DATA__
 CJK統合漢字        | CJK Unified Ideographs                  | 4E00        | 9FBF
 CJK統合漢字拡張A   | CJK Unified Ideographs Extension A      | 3400        | 4DBF
 CJK統合漢字拡張B   | CJK Unified Ideographs Extension B      | 20000       | 2A6DF
 CJK統合漢字拡張C   | CJK Unified Ideographs Extension C      | 2A700       | 2B73F
 CJK統合漢字拡張D   | CJK Unified Ideographs Extension D      | 2B740       | 2B81F
 CJK互換漢字        | CJK Compatibility Ideographs            | F900        | FAFF
 CJK互換漢字補助    | CJK Compatibility Ideographs Supplement | 2F800       | 2FA1D
 漢文用記号         | Kanbun                                  | 3190        | 319F
 CJK部首補助        | CJK Radicals Supplement                 | 2E80        | 2EFF
 康煕部首           | CJK Radicals                            | 2F00        | 2FDF
 CJK字画            | CJK Strokes                             | 31C0        | 31EF
 漢字構成記述文字   | Ideographic Description Characters      | 2FF0        | 2FFF
 注音字母           | Bopomofo                                | 3100        | 312F
 注音字母拡張       | Bopomofo Extended                       | 31A0        | 31BF
 半角・全角形       | Halfwidth and Fullwidth Forms           | FF00        | FFEF
 平仮名             | Hiragana                                | 3040        | 309F
 片仮名             | Katakana                                | 30A0        | 30FF
 片仮名表音拡張     | Katakana Phonetic Extensions            | 31F0        | 31FF
 仮名補助           | Kana Supplement                         | 1B000       | 1B0FF
 ハングル音節文字   | Hangul Syllables                        | AC00        | D7AF
 ハングル字母       | Hangul Jamo                             | 1100        | 11FF
 ハングル字母拡張A  | Hangul Jamo Extended A                  | A960        | A97F
 ハングル字母拡張B  | Hangul Jamo Extended B                  | D7B0        | D7FF
 ハングル互換字母   | Hangul Compatibility Jamo               | 3130        | 318F
 彝音節文字         | Yi Syllables                            | A000        | A48F
 彝文字部首         | Yi Radicals                             | A490        | A4CF
