#!/usr/bin/env perl
package kitco;

use strict;
use warnings;
use LWP::Simple;
use File::Spec;         # catfile catdir
use File::Basename;     # dirname

my $datadir  = File::Spec->catdir(dirname(__FILE__), '..', 'data');
my $outfile  = File::Spec->catfile($datadir, 'LondonFixMetal.csv');

my $kitco_current_url = "http://www.kitco.com/gold.londonfix.html";
my $kitco_historical_url_prefix =
    'http://www.kitco.com/londonfix/gold.londonfix';

my $date_pat = qr/((?:\d{4}-\d{2}-\d{2})|(?:\w+\s+\d+,\s*\d{4}))/;
my $price_pat = qr#<(?:p|b)>([\d\w\.\-\s\,<>\\]*)</(?:p|b)>#i;
my $header = "Date,Gold:AM,Gold:PM,Silver,Platinum:AM,Platinum:PM,Palladium:AM,Palladium:PM";
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

#----------
# example: 1996-2005
# Multi-line
#    <tr ALIGN="CENTER"> 
#      <TD bgColor=#f3f3e4 COLSTART="1"><b>December 24, 1997</b></td>
#      <TD bgColor=#f3f3e4 COLSTART="2"><b>296.10</b></td>
#      <TD bgColor=#f3f3e4 COLSTART="3"><b>Closed</b></td>
#      <TD bgColor=#f3f3e4 COLSTART="4"><b>6.2675</b></td>
#      <TD bgColor=#f3f3e4 COLSTART="5"><b>359.00</b></td>
#      <TD bgColor=#f3f3e4 COLSTART="6"><b>Closed</b></td>
#      <TD bgColor=#f3f3e4 COLSTART="7"><b>191.00</b></td>
#      <TD bgColor=#f3f3e4 COLSTART="8"><b>Closed</b></td>
#    </tr>
#
# example: 2006-
# Single line
# <tr align=middle><td height=24 bgcolor=#f3f3e4><p>2011-12-29</p></td><td height=24 bgcolor=#e1e1bd><p>1537.50</p></td><td height=24 bgcolor=#cccc99><p>1531.00</p></td><td height=24 bgcolor=#e2e2e2><p>26.1600</p></td><td height=24 bgcolor=#e1e1bd><p>1364.00</p></td><td height=24 bgcolor=#cccc99><p>1354.00</p></td><td height=24 bgcolor=#e1e1bd><p>636.00</p></td><td height=24 bgcolor=#cccc99><p>630.00</p></td></tr>

#----------
# Input: Format as Aug 25, 2002
# Output: 2002-08-25
#----------
sub normalize_date {
    my $date = shift;
    my ($day, $month, $year);
    $date =~ /(\w+)\s+(\d+),\s*(\d+)/;
    ($month, $day, $year) = ($1, $2, $3);

    for (my $m=0; $m<12; $m++) {
        if ($month =~ $months[$m]) {
            $month = $m+1;
            last;
        }
    } 
    return sprintf("%s-%02d-%02d", $year, $month, $day);
}

#----------
# Get content of urls and save them into files.
# Input: urls
# Output: Filenames
#----------
sub get_save_urls {
    my $urllist = shift;
    my $files = [];
    for my $url (@{$urllist}) {
        $url =~ /\/([^\/]+)$/;
        my $file = File::Spec->catfile($datadir, $1);
        push @$files, $file;
        next if (-e $file);
        
        my $content = get($url) or die "Cannot get $url";
        open(my $fh, ">", $file) or die "Cannot open > $file";
        $fh->write($content);
        close($fh);
    }
    return $files;
}

#-----
# Input: (input filename, output filename, newer than the date)
#   $newer_than is a optional condition. Only records newer than this date are stored.
#   The parameter is useful for incremental updating.
#-----
sub get_price {
    my ($ifile, $ofile, $newer_than) = @_;
    open(my $ifh, '<', $ifile) or die "Cannot open $ifile";
    open(my $ofh, '>>', $ofile) or die "Cannot write $ofile";

    # Save result to @d so that we can reverse order
    my @d;

    # Keep only data within TR tag
    chomp(my @lines = <$ifh>);
    my $content = join('', @lines);
    close($ifh);
    my @rows = $content =~ m/<tr.*?<\/tr>/ig;

    for my $line (@rows) {
        next if $line !~ $date_pat;
        my $date = $1;
        # Get prices
        my @p = $line =~ m/$price_pat/g;
        # First element is date.
        shift @p;
        # Skip partial result
        next if ($#p!=6);
        # Remove non-digital in each price, which means not available
        @p = map {$_=$_||''; $_ =~ s/[^\d\.]//g; $_} @p;
        if ($date !~ /^\d/) {
            $date = normalize_date($date);
        }
        my $s = "$date," . join(',',@p) . "\n";
        push @d, $s;
    }

    if (defined $newer_than) {
        @d = grep {$_ gt $newer_than} @d;
    }
        
    local $, = '';
    print $ofh reverse(@d);
    close($ofh);
}

sub get_hist_prices {
    my ($urllist, $last_rec, $del_ifile) = @_;

    for my $url (@{$urllist}) {
        $url =~ /\/([^\/]+)$/;
        my $ifile = File::Spec->catfile($datadir, $1);
        next if !(-e $ifile);

        get_price($ifile, $outfile, $last_rec);

        unlink($ifile) if defined($del_ifile);
    }
}

sub get_last_record {
    my $file = shift;
    my $last_rec = '1996-01-01';
    open(my $fh, '<', $file) or return $last_rec;
    while(<$fh>) {
        $last_rec = $_ if $_ =~ /\S+/;
    }
    close($fh);
    return $last_rec;
}

sub main {
    # Prepare csv header
    if (! -e $outfile) {
        open(my $ofh, '>', $outfile) or die "Cannot write $outfile";
        print $ofh "$header\n";
        close($ofh);
    }

    my @t = localtime(time);
    my $year_cur = $t[5]+1900;
    my $last_rec = get_last_record($outfile);
    my $year_rec = $1;
    if ($last_rec =~ /([\d]+)/) {
        $year_rec = $1;
    } else {
        $year_rec = 1996;
        $last_rec = '1996-01-01';
    }

    for (; $year_rec <= $year_cur; $year_rec++) {
        my ($url, $del_html); 
        if ($year_rec < $year_cur) {
            # Previous years
            my $short_year = sprintf("%02d", $year_rec>=2000 ? $year_rec-2000 : $year_rec-1900);
            $url = $kitco_historical_url_prefix . $short_year . '.html'; 
        } else {
            # Current year
            $url = $kitco_current_url;
            $del_html = 1;
        }
        my $file = get_save_urls([$url])->[0];
        get_hist_prices([$url], $last_rec, $del_html);
    }
}

main() unless caller();

1;
__END__
=head1 NAME
Getting historical prices on kitco.com

=head1 SYNOPSIS
    $ perl kitco.pm

The program will get data and store result in ../data/LondonFix.cvs

=head1 DESCRIPTION
www.kitcom.com provides historical prices of gold, silver, and 2 other kinds
of metals. This modules get data from website and saves it in a file.

=head1 AUTHOR
Jyun-Fan Tsai <jyunfan@gmail.com>
