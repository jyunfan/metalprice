package kitco;

use strict;
use warnings;
use LWP::Simple;
use File::Spec;         # catfile catdir
use File::Basename;     # dirname

my $datadir = File::Spec->catdir(dirname(__FILE__), '..', 'data');

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

sub get_urls {
    my $urllist = shift;
    for my $url (@{$urllist}) {
        $url =~ /\/([^\/]+)$/;
        my $file = File::Spec->catfile($datadir, $1);
        next if (-e $file);
        
        my $content = get($url) or die "Cannot get $url";
        open(my $fh, ">", $file) or die "Cannot open > $file";
        $fh->write($content);
        close($fh);
    }
}

sub get_price {
    my ($ifile, $ofile) = @_;
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

    local $, = '';
    print $ofh reverse(@d);
    close($ofh);
}

sub get_hist_prices {
    my $urllist = shift;
    
    my $ofile = File::Spec->catfile($datadir, 'LondonFixMetal.csv');
    return if (-e $ofile);

    open(my $ofh, '>', $ofile) or die "Cannot write $ofile";
    print $ofh "$header\n";
    close($ofh);

    for my $url (@{$urllist}) {
        $url =~ /\/([^\/]+)$/;
        my $ifile = File::Spec->catfile($datadir, $1);
        next if !(-e $ifile);

        get_price($ifile, $ofile);
    }
}

sub main {
    # Ensure that the HTML is in our disk
    get_urls($kitco_historical_urls);
    
    get_hist_prices($kitco_historical_urls); 
}

main() unless caller();

1;
__END__
=head1 NAME
Getting historical prices on kitco.com

=head1 SYNOPSIS
    $ perl kitco.pm

The program will get data and store ../data/LondonFix.cvs

=head1 DESCRIPTION
www.kitcom.com provides historical prices of gold, silver, and 2 other kinds
of metals. This modules get data from website and saves it in a file.

=head1 AUTHOR
Jyun-Fan Tsai <jyunfan@gmail.com>
