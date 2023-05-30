# Copyright (C) 2005  Erik Tjong Kim Sang
#                     Edgar Gonzàlez i Pellicer
#                     Maria Fuentes Fort
#
# This file is part of AutoPan
#
# AutoPan is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# English Tokenizer
# Class EngTok

package EngTok;

use strict;


# Constructor
sub new {
    my ($pkg) = @_;

    my $tok = [ {} ];

    ## abbreviations
    my @abbrev = qw( apr aug av bldg co dec dr calif corp feb fla inc jan jr jul jun lt ltd mar mr mrs ms mt no nov oct rev sep sept st vol vols vs );
    my $a;
    foreach $a (@abbrev) { $tok->[0]{$a} = 1; }

    return bless $tok, $pkg;
}


# Tokenize a string
sub tokenizeString {
    my ($this, $line, $lf) = @_;

    # Fem separacio d'oracions o no
    $lf = 0 if !defined($lf);

    $line =~ s/^\s*//;
    $line =~ s/\s*$//;
    my @T = split(/\s+/,$line);

    my $i = 0;
    while ($i <= $#T) {
        # Remove double quotes '' or `` and substitute by "
        # at the beggining of word

            # remove sentence breaking punctuation with quote from end of word
        if ($T[$i] =~ /^([`][`]|[']['])(.+)$/) {
            splice(@T,$i,1,'`',$2);
            $i++;

            # remove punctuation from start of word
        } elsif ($T[$i] =~ /^(["])(.+)$/) {
            splice(@T,$i,1,'`',$2);
            $i++;

            # change sentence breaking punctuation with double quote '' from end of word
        } elsif ($T[$i] =~ /^([`'\(\)\[\]\$:;,\/\%])(.+)$/ and
                 $T[$i] !~ /^'[dsm]$/i and $T[$i] !~ /^'re$/i and
                 $T[$i] !~ /^'ve$/i and $T[$i] !~ /^'ll$/i) {
            splice(@T,$i,1,$1,$2);
            $i++;

            # change sentence breaking punctuation with double quote '' from end of word
        } elsif ($T[$i] =~ /^(.+)([?!\.])(['][']|[`][`])$/) {
            if ($lf) { splice(@T,$i,1,"\n",$2); }
            else     { splice(@T,$i,1,'`',$2); }
            splice(@T,$i,1,$1,$2,'`');

            # remove sentence breaking punctuation with quote from end of word
        } elsif ($T[$i] =~ /^(.+)([?!\.])(['])$/) {
            if ($lf) { splice(@T,$i,1,$1,"$2$3","\n"); }
            else     { splice(@T,$i,1,$1,$2,$3); }

            # remove sentence breaking punctuation with quote from end of word
        } elsif ($T[$i] =~ /^(.+)([?!\.])(["])$/) {
            if ($lf) { splice(@T,$i,1,$1,"$2$3","\n"); }
            else     { splice(@T,$i,1,$1,$2,'`'); }

            # change non-sentence-breaking punctuation from end of word
        } elsif ($T[$i] =~ /^(.+)([']['])$/) {
            splice(@T,$i,1,$1,'`');

            # remove non-sentence-breaking punctuation from end of word
        } elsif ($T[$i] =~ /^(.+)(["])$/) {
            splice(@T,$i,1,$1,'`');

            # remove non-sentence-breaking punctuation from end of word
        } elsif ($T[$i] =~ /^(.+)([:;,`'\)\(\[\]\%])$/) {
            splice(@T,$i,1,$1,$2);

            # remove sentence-breaking punctuation (not period) from end of word
        } elsif ($T[$i] =~ /^(.+)([?!])$/ or
                 $T[$i] =~ /^(.+[^\.])(\.\.+)$/) {
            if ($lf) { splice(@T,$i,1,$1,$2,"\n"); }
            else     { splice(@T,$i,1,$1,$2); }

            # separate currency symbol from value
        } elsif ($T[$i] =~ /^([A-Za-z]+\$)(.+)$/i) {
            splice(@T,$i,1,$1,$2);
            $i++;

            # separate currency symbol other symbols
        } elsif ($T[$i] =~ /^(.*)-\$(.*)$/i) {
            splice(@T,$i,1,$1,"-","\$",$2);
            $i++;

            # split words like we're did't etcetera
        } elsif ($T[$i] =~ /^(.+)('re|'ve|'ll|n't|'[dsm])$/i) {
            splice(@T,$i,1,$1,$2);

            # split words with punctuation in the middle
        } elsif ($T[$i] =~ /^(.*[a-z].*)([",\(\)])(.*[a-z].*)$/i) {
            splice(@T,$i,1,$1,$2,$3);

            # separate words linked with sequence (>=2) of periods
        } elsif ($T[$i] =~ /^(.*[^\.])(\.\.+)([^\.].*)$/) {
            splice(@T,$i,1,"$1$2",$3);

            # remove initial hyphens from word
        } elsif ($T[$i] =~ /^(-+)([^\-].*)$/ and $T[$i] ne "-DOCSTART-") {
            splice(@T,$i,1,$1,$2);

            # separate number and word linked with hyphen
        } elsif ($T[$i] =~ /^([0-9\/]+)-([A-Z][a-z].*)$/) {
            splice(@T,$i,1,$1,"-",$2);

            # separate number and word linked with period
        } elsif ($T[$i] =~ /^([0-9\/]+)\.([A-Z][a-z].*)$/) {
            splice(@T,$i,1,"$1.",$2);

            # separate number and word linked with period
        } elsif ($T[$i] =~ /^(.*)\.-([A-Z][a-z].*)$/) {
            splice(@T,$i,1,"$1.","-",$2);

            # separate initial from name
        } elsif ($T[$i] =~ /^([A-Z]\.)([A-Z][a-z].*)$/) {
            splice(@T,$i,1,$1,$2);

            # introduce sentence break after number followed by period
        } elsif ($i != 0 and $T[$i] =~ /^(.*[0-9])(\.)$/) {
            splice(@T,$i,1,$1,$2);

            # split words containing a slash if they are not a URI
        } elsif ($T[$i] !~ /^(ht|f)tps*/i and
                 $T[$i] =~ /[^0-9\/\-]/ and
                 $T[$i] =~ /^(.+)\/(.+)$/) {
            splice(@T,$i,1,$1,"/",$2);

            # put sentence break after period if it is not an abbreviation
        } elsif ($T[$i] =~ /^(.+)(\.)$/ and $T[$i] !~ /^\.+$/ and
                 $T[$i] !~ /^[0-9]+\./) {
            my $word = $1;
            if ($i != $#T and $this->abbrev($word)) { $i++; }
            else {
                if ($lf) { splice(@T,$i,1,$1,$2,"\n"); }
                else     { splice(@T,$i,1,$1,$2); }
            }
        } else { $i++; }
    }

    return @T;
}


# Is it an abbreviation
sub abbrev {
    my ($this, $word) = @_;

    $word =~ tr/[A-Z]/[a-z]/;
    if ($word =~ /\./ and $word !~ /[0-9]/) { return(1); };
    if ($word =~ /^[a-z]$/) { return(1); };
    return(defined $this->[0]{$word});
}


# Return true
1;
