#!/usr/bin/perl

use strict;
use warnings;
use List::MoreUtils qw(uniq);

my $mdfile = "supported-robots.md";

open my $in, "<$mdfile" or die "Could not open '$mdfile': $!\n"
    . "You can fetch it from https://raw.githubusercontent.com/Hypfer/Valetudo/master/docs/_pages/general/supported-robots.md\n";

my $outdir = shift;
$outdir =~ s@/$@@ if defined $outdir; 

print "No output directory supplied, just parsing the data!\n" unless defined $outdir;

my %robots;
my $in_toc = 0;
my $manufacturer = "";
my $n = 0;
while (my $line = <$in>) {
    ++$n;
    # strip trailing whitespaces
    $line =~ s/\s*$//;
    if ($line =~ m/.*\[Xiaomi\]/) {
        $in_toc = 1;
    } elsif (!$in_toc) {
        next;
    }
    
    ++$in_toc;
    if ($line =~ m/^\s*$/ and $in_toc > 3) {
        # 1. [Xiaomi](#xiaomi)
        last;
    } elsif ($line =~ m/^\d+\. \[(.*)\]\(.*\)$/) {
        $manufacturer = $1;
    } elsif ($line =~ m/\s+\d+\. \[(.*)\]\(#(.*)\)$/) {
        #   6. [Vacuum-Mop 2 Ultra](#xiaomi_p2150)
        my $model = $1;
        my $id = $2;
        die "Duplicate id '$id'!\n" if defined $robots{$id};
        $robots{$id} = { 
            "manufacturer" => $manufacturer,
            "models" => ["$manufacturer $model"],
            "models_lines" => [$n],
            "id" => $id
        };
    }
}

my $bot_id = undef;
my $sold_as = 0;
while (my $line = <$in>) {
    ++$n;
    $line =~ s/\s*$//;
    if ($line =~ m/^###.*id="([^"]+)"/) {
        $bot_id = $1;
        die "Bad id at line $n: $bot_id\n" unless defined $robots{$bot_id};
    } elsif ($line =~ m/.*sold as:\s*$/) {
        $sold_as = 1;
    } elsif ($sold_as == 1 and $line =~ m/- \s*(.*)/) {
        my $as = $1;
        push @{$robots{$bot_id}{"models"}}, $as;
        push @{$robots{$bot_id}{"models_lines"}}, $n;
    } elsif ($sold_as == 1) {
        $sold_as = 0;
    }
}

close $in;

sub add_keywords {
    my $keywords = shift;
    my $string = shift;
    foreach my $substr (split(" ", lc $string)) {
        next if $substr =~ m/^[^a-z0-9]{1}$/;
        $keywords->{$substr} = 1;

        my $clean = $substr;
        $clean =~ s/[^a-z0-9_]//g;
        if ($clean ne "" and $clean ne $substr) {
            $keywords->{$clean} = 1;
        }
    }
}

foreach my $id (sort keys %robots) {
    print "ID: $id\n";
    $n = 0;
    my %keywords;
    foreach my $model (uniq sort @{$robots{$id}{"models"}}) {
        add_keywords(\%keywords, $model);
        print "  - $model (",$robots{$id}{"models_lines"}[$n],")\n";
        ++$n;
    }
    add_keywords(\%keywords, $id);
    my $keywords = join(", ", sort keys %keywords);
    print "  => $keywords\n"; 

    next unless $outdir;

    my @uniq_models = uniq @{$robots{$id}{"models"}};
    @uniq_models = sort @uniq_models;
    my $fname = "$outdir/$id.txt";
    die "Duplicate filename '$fname'!" if -e $fname;
    open my $out, ">$fname" or die "Could not open '$fname': $!\n";
    my $aka = "";
    if (scalar @uniq_models > 1) {
        $aka = join ("\n - ", "\nThis robot is also known as:", @uniq_models);
    }
    print $out <<"EOF"
keywords: $keywords
title: $robots{$id}{"models"}[0]
short-title: $id
text:
You can find rooting information at https://valetudo.cloud/pages/general/supported-robots.html#$id$aka
EOF
    ;
    close $out;
}
