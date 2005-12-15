# Copyright (C)  Martin Porter
#                Edgar Gonzàlez i Pellicer
#                Maria Fuentes Fort
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

# Porter Stemmer
#
# Adapted from:
# http://www.tartarus.org/~martin/PorterStemmer

use strict;

use IO::File;


package Porter;

use vars qw( %step2list %step3list
	     $c $v $C $V $mgr0 $meq1 $mgr1 $_v );

# Static vars
%step2list =
    ( 'ational'=>'ate', 'tional'=>'tion', 'enci'=>'ence',
      'anci'=>'ance', 'izer'=>'ize', 'bli'=>'ble',
      'alli'=>'al', 'entli'=>'ent', 'eli'=>'e',
      'ousli'=>'ous', 'ization'=>'ize', 'ation'=>'ate',
      'ator'=>'ate', 'alism'=>'al', 'iveness'=>'ive',
      'fulness'=>'ful', 'ousness'=>'ous', 'aliti'=>'al',
      'iviti'=>'ive', 'biliti'=>'ble', 'logi'=>'log');

%step3list =
    ('icate'=>'ic', 'ative'=>'', 'alize'=>'al', 
     'iciti'=>'ic', 'ical'=>'ic', 'ful'=>'', 'ness'=>'');


$c = qr/[^aeiou]/;          # consonant
$v = qr/[aeiouy]/;          # vowel
$C = qr/${c}[^aeiouy]*/;    # consonant sequence
$V = qr/${v}[aeiou]*/;      # vowel sequence

$mgr0 = qr/^(${C})?${V}${C}/;         # [C]VC... is m>0
$meq1 = qr/^(${C})?${V}${C}(${V})?$/; # [C]VC[V] is m=1
$mgr1 = qr/^(${C})?${V}${C}${V}${C}/; # [C]VCVC... is m>1
$_v   = qr/^(${C})?${v}/;             # vowel in stem


# Constructor
sub new {
    my ($class, $stopWordFile) = @_;

    # Stop word part
    my $stopList = {};

    # Load it
    if ($stopWordFile) {
	my $fin = new IO::File("< $stopWordFile")
	    or die "Can't Open Stop Word File $stopWordFile\n";
	
	my $line;
	while ($line = $fin->getline()) {
	    chomp($line);
	    $stopList->{lc($line)} = 1 if $line;
	}
	$fin->close();
    }
    
    # Add the cache part and bless
    return bless([ $stopList, {}], $class);
}


# Stem
sub stem {
    my ($this, $w) = @_;
    $w = lc($w);

    # Is it a punctuation or number?
    return if $w =~ /^\W+$/;

    # Is it a number
    return $w if $w =~/^[\d.]+$/;

    # Is it a stop word?
    return if $this->[0]{$w};

    # Length at least 3
    return $w if length($w) < 3;

    # Look in the cache
    return $this->[1]{$w} if exists($this->[1]{$w});
    
    # Save starting $w
    my $initw = $w;

    # Temporary
    my ($stem, $suffix, $firstch);

    # now map initial y to Y so that the patterns never treat it as vowel:
    $w =~ /^./; $firstch = $&;
    if ($firstch =~ /^y/) { $w = ucfirst $w; }

    # Step 1a
    if ($w =~ /(ss|i)es$/) { $w=$`.$1; }
    elsif ($w =~ /([^s])s$/) { $w=$`.$1; }
 
   # Step 1b
    if ($w =~ /eed$/) { if ($` =~ /$mgr0/o) { chop($w); } }
    elsif ($w =~ /(ed|ing)$/) { 
	$stem = $`;
	if ($stem =~ /$_v/o) {
	    $w = $stem;
	    if ($w =~ /(at|bl|iz)$/) { $w .= "e"; }
	    elsif ($w =~ /([^aeiouylsz])\1$/) { chop($w); }
	    elsif ($w =~ /^${C}${v}[^aeiouwxy]$/o) { $w .= "e"; }
        }
    }

    # Step 1c
    if ($w =~ /y$/) { $stem = $`; if ($stem =~ /$_v/o) { $w = $stem."i"; } }

    # Step 2
    if ($w =~ /(ational|tional|enci|anci|izer|bli|alli|entli|eli|ousli|ization|ation|ator|alism|iveness|fulness|ousness|aliti|iviti|biliti|logi)$/) {
        $stem = $`; $suffix = $1;
        if ($stem =~ /$mgr0/o) { $w = $stem . $step2list{$suffix}; }
    }

    # Step 3
    if ($w =~ /(icate|ative|alize|iciti|ical|ful|ness)$/) {
        $stem = $`; $suffix = $1;
        if ($stem =~ /$mgr0/o) { $w = $stem . $step3list{$suffix}; }
    }

    # Step 4
    if ($w =~ /(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ou|ism|ate|iti|ous|ive|ize)$/) {
        $stem = $`;
        if ($stem =~ /$mgr1/o) { $w = $stem; }

    } elsif ($w =~ /(s|t)(ion)$/) {
        $stem = $` . $1;
        if ($stem =~ /$mgr1/o) { $w = $stem; }
    }


    #  Step 5
    if ($w =~ /e$/) {
        $stem = $`;
        if ($stem =~ /$mgr1/o or
            ($stem =~ /$meq1/o and not $stem =~ /^${C}${v}[^aeiouwxy]$/o))
        { $w = $stem; }
    }
    if ($w =~ /ll$/ and $w =~ /$mgr1/o) { chop($w); }

    # and turn initial Y back to y
    if ($firstch =~ /^y/) { $w = lcfirst($w); }

    # Add to the cache
    $this->[1]{$initw} = $w;

    return $w;
}


# Is a stop word
sub isStopWord {
    my ($this, $w) = @_;

    return ($w =~ /^\W+$/ || $this->[0]{$w});
}



# Is a non word
sub isNonWord {
    my ($this, $w) = @_;

    return $w =~ /^\W+$/;
}


# Return true
1;

