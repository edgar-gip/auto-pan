# Copyright (C) 2005  Edgar Gonzàlez i Pellicer
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

use strict;

# SCU
package SCU;

# Constructor
sub new {
    my ($class, $subtree, $options) = @_;

    my $uid   = $subtree->[0]{'uid'};
    my $label = $subtree->[0]{'label'};

    # Process the string
    my $labelWords = processString($label, $options);

    # Contributors
    my @contributors = ();

    # Process the children
    shift(@{$subtree});
    while (@{$subtree}) {
        my $tag   = shift(@{$subtree});
        my $child = shift(@{$subtree});

        if ($tag eq 'contributor') {
            # Find the contributor words
            my $words = processString($child->[0]{'label'}, $options);
            push(@contributors, [ $words, $child->[0]{'label'} ])
                if @{$words} >= $options->{'mincontri'};
        }
    }

    # Return the object
    return bless([ $uid, $label, $labelWords, \@contributors ], $class);
}

# Process the string
sub processString {
    my ($string, $options) = @_;

    # Tokenize
    my @words = $options->{'tokenizer'}->tokenizeString($string);

    # Lower case and stem
    if ($options->{'stem'}) {
        @words = map { $options->{'stemmer'}->stem($_) } @words;

    } elsif ($options->{'lower'}) {
        @words = map { lc($_) } @words;
        if ($options->{'stop'}) {
            @words = grep { !$options->{'stemmer'}->isStopWord($_) } @words;
        } else {
            @words = grep { !$options->{'stemmer'}->isNonWord($_) } @words;
        }

    } elsif ($options->{'stop'}) {
        @words = grep { !$options->{'stemmer'}->isStopWord(lc($_)) } @words;

    } else {
        @words = grep { !$options->{'stemmer'}->isNonWord($_) } @words;
    }

    # Filter the words
    @words = removeRepeated(@words);

    # Return
    return \@words;
}

# Remove repeated elements
sub removeRepeated {
    my @elements = sort(@_);

    my $i = 1;
    while ($i < @elements) {
        if ($elements[$i] eq $elements[$i - 1]) {
            splice(@elements, $i, 1);
        } else {
            ++$i;
        }
    }

    return @elements;
}

# Get the overlap with a section
# (represented as a hash)
sub getLeftmostOverlap {
    my ($this, $sectionHash, $useContributors) = @_;

    # Overlap with the label
    my $label = $this->getLabelWords();
    my ($maxOverlap, $maxLeftMost) =
        _getLeftmostOverlap($label, $sectionHash);
    my $maxContribText = $this->getLabel();

    # If no use contributors, return this
    return ($maxOverlap, $maxLeftMost, $maxContribText)
        if !$useContributors;

    # Overlap with each contributor
    my $maxContributorText;
    foreach my $contrib ($this->getContributors()) {
        my ($overlap, $leftMost) =
            _getLeftmostOverlap($contrib->[0], $sectionHash);
        if ($overlap > $maxOverlap) {
            $maxOverlap     = $overlap;
            $maxLeftMost    = $leftMost;
            $maxContribText = $contrib->[1];

        } elsif ($overlap == $maxOverlap &&
                 $leftMost < $maxLeftMost) {
            $maxLeftMost    = $leftMost;
            $maxContribText = $contrib->[1];
        }
    }

    # Return the best of the best
    return ($maxOverlap, $maxLeftMost, $maxContribText);
}

# Auxiliary overlap function
sub _getLeftmostOverlap {
    my ($reference, $sectionHash) = @_;

    my $overlap  = 0;
    my $leftMost = 1000;

    foreach my $elem (@{$reference}) {
        if (exists($sectionHash->{$elem})) {
            ++$overlap;
            if ($sectionHash->{$elem} < $leftMost) {
                $leftMost = $sectionHash->{$elem};
            }
        }
    }

    # Return relative overlap
    return ($overlap / @{$reference}, $leftMost);
}

# Get the uid
sub getUid { return $_[0]->[0]; }

# Get the label
sub getLabel { return $_[0]->[1]; }

# Get the label words
sub getLabelWords { return $_[0]->[2]; }

# Get contributors
sub getContributors { return @{$_[0]->[3]}; }

# Get the score
sub getScore { return scalar(@{$_[0]->[3]}); }

# Return true
1;
