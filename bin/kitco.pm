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
my $kitco_historical_urls = [
#    'http://www.kitco.com/londonfix/gold.londonfix05.html',
    'http://www.kitco.com/londonfix/gold.londonfix06.html',
    'http://www.kitco.com/londonfix/gold.londonfix07.html',
    'http://www.kitco.com/londonfix/gold.londonfix08.html',
    'http://www.kitco.com/londonfix/gold.londonfix09.html',
    'http://www.kitco.com/londonfix/gold.londonfix10.html',
    'http://www.kitco.com/londonfix/gold.londonfix11.html'
];

my $date_pat = qr/(\d{4}-\d{2}-\d{2}|\w+\s+\d+,\s+\d{4})/;
my $price_pat = qr#<p>([\d.]+|-)</p>#;
my $header = "Date,Gold:AM,Gold:PM,Silver,Platinum:AM,Platinum:PM,Palladium:AM,Palladium:PM";

#-----
# Get content of urls and save them into files.
# Input: urls
# Output: Filenames
#-----
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
# Input: (input filename, output filename, a string condition)
#   $newer_than is a optional condition. Only records newer than this date are stored.
#   The parameter is useful for incremental updating.
#-----
sub get_price {
    my ($ifile, $ofile, $newer_than) = @_;
    open(my $ifh, '<', $ifile) or die "Cannot open $ifile";
    open(my $ofh, '>>', $ofile) or die "Cannot write $ofile";

    # Save result to @d so that we can reverse order
    my @d;

    while(<$ifh>) {
        my $line = $_;
        next if $line !~ $date_pat;
        my $date = $1;
        my @p = $line =~ m/$price_pat/g;
        @p = map {$_ =~ s/\-//; $_} @p;     # Remove '-' in prices
        my $s = "$date," . join(',',@p) . "\n";
        push @d, $s;
    }
    close($ifh);

    if (defined $newer_than) {
        @d = grep {$_ gt $newer_than} @d;
    }
        
    local $, = '';
    print $ofh reverse(@d);
    close($ofh);
}

sub get_hist_prices {
    my $urllist = shift;
    
    return if (-e $outfile);

    open(my $ofh, '>', $outfile) or die "Cannot write $outfile";
    print $ofh "$header\n";
    close($ofh);

    for my $url (@{$urllist}) {
        $url =~ /\/([^\/]+)$/;
        my $ifile = File::Spec->catfile($datadir, $1);
        next if !(-e $ifile);

        get_price($ifile, $outfile);
    }
}

sub get_last_date {
    my $file = shift;
    my $last_date;
    open(my $fh, '<', $file) or die "Cannot open $file";
    while(<$fh>) {
        $last_date = $_ if $_ =~ /\S+/;
    }
    close($fh);
    return $last_date;
}

sub main {
    # Ensure that the HTML is in our disk
    get_save_urls($kitco_historical_urls);
    get_hist_prices($kitco_historical_urls); 

    my $last_date = get_last_date($outfile);
    my $file = get_save_urls([$kitco_current_url])->[0];
    get_price($file, $outfile, $last_date);
    unlink($file) if (-e $file); 
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
