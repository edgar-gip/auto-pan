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

use XML::Parser;

use SCU;
use Alignment;

# Pyramid contents
package Pyramid;

# Constructor
sub new {
    my ($class, $file, %options) = @_;

    # Load the XML File
    my $parser = new XML::Parser('Style' => 'Tree');
    my $tree;
    eval {
        $tree   = $parser->parsefile($file);
    };
    die "File $file is not a valid XML file: $@" if $@;

    # Follow the tree
    die "Root of file is not a <pyramid>\n" if $tree->[0] ne 'pyramid';

    # Write the pyramid before modifying it
    $options{'writer'}->printPyramid($tree);

    # Skip attributes
    shift(@{$tree->[1]});

    # Result
    my $result = [];

    # Skip the text part and read every SCU
    while (@{$tree->[1]}) {
        my $tag     = shift(@{$tree->[1]});
        my $subtree = shift(@{$tree->[1]});

        if ($tag eq 'scu') {
            push(@{$result}, new SCU($subtree, \%options));
        }
    }

    # Return
    return bless([ $result ], $class);
}

# Non-greedy align summary
sub alignSummary {
    my ($this, $summary, $minOverlap, $useContributors) = @_;

    # Output
    my @alignments = ();

    # Sentence counter
    my $sentCounter;
    foreach my $sentence ($summary->getSentences()) {
        # One more sentence
        ++$sentCounter;

        my ($tokens, $words) = @{$sentence};
        my @matches;

        my %sectionHash;

        # Dynamic arrays
        my @dynamicScore;
        my @dynamicIncr;
        my @dynamicRight;
        my @dynamicLeft;
        my @dynamicScu;
        my @dynamicOvlp;
        my @dynamicText;

        # Set the value for the segment 0 - 0
        $dynamicScore[0] = 0;
        $dynamicIncr [0] = 0;
        $dynamicRight[0] = -1;
        $dynamicLeft [0] = -1;
        $dynamicScu  [0] = undef;
        $dynamicOvlp [0] = undef;
        $dynamicText [0] = undef;

        # Can we improve them?
        if (defined($words->[0])) {
            $sectionHash{$words->[0]} = 0;
            my ($score, $left, $scu, $ovlp, $text) =
                $this->overlaps(\%sectionHash, $useContributors,
                                $minOverlap);
            if ($score > -1) {
                $dynamicScore[0] = $score;
                $dynamicIncr [0] = $score;
                $dynamicRight[0] = 0;
                $dynamicLeft [0] = 0;
                $dynamicScu  [0] = $scu;
                $dynamicOvlp [0] = $ovlp;
                $dynamicText [0] = $text;
            }
        }

        # Dynamic programming
        for (my $end = 1; $end < @{$tokens}; ++$end) {
            # Start with the previous
            $dynamicScore[$end] = $dynamicScore[$end - 1];
            $dynamicIncr [$end] = 0;
            $dynamicRight[$end] = $dynamicRight[$end - 1];
            $dynamicLeft [$end] = $dynamicLeft [$end - 1];
            $dynamicScu  [$end] = undef;
            $dynamicOvlp [$end] = undef;
            $dynamicText [$end] = undef;

            # Try improving it if it may be improved
            if (defined($words->[$end])) {
                %sectionHash = ();

                for (my $begin = $end; $begin >= 0; --$begin) {
                    # A new word to be added?
                    next if !defined($words->[$begin]);

                    # If it is already there, nothing
                    next if exists($sectionHash{$words->[$begin]});

                    # Try adding it
                    $sectionHash{$words->[$begin]} = $begin;

                    # Overlaps?
                    my ($score, $left, $scu, $ovlp, $text) =
                        $this->overlaps(\%sectionHash, $useContributors,
                                        $minOverlap);
                    if ($score > -1) {
                        my $incr = $score;
                        $score += $dynamicScore[$left - 1] if $left > 0;

                        # Is the score best than the current?
                        if ($score > $dynamicScore[$end] ||
                            ($score == $dynamicScore[$end] &&
                             $left < $dynamicLeft[$end])) {

                            $dynamicScore[$end] = $score;
                            $dynamicIncr [$end] = $incr;
                            $dynamicRight[$end] = $end;
                            $dynamicLeft [$end] = $left;
                            $dynamicScu  [$end] = $scu;
                            $dynamicOvlp [$end] = $ovlp;
                            $dynamicText [$end] = $text;
                        }
                    }
                }
            }
        }

        # Reconstruct the solution
        my $right = $dynamicRight[@{$tokens} - 1];

        while ($right != -1) {
            my $left = $dynamicLeft[$right];
            unshift(@matches,
                    new Alignment($sentCounter,
                                  $left, $right, $dynamicOvlp[$right],
                                  $dynamicScu[$right]->getLabel(),
                                  $dynamicScu[$right]->getUid(),
                                  $dynamicScu[$right]->getScore(),
                                  $dynamicIncr[$right],
                                  $dynamicText[$right],
                                  join(' ', @{$tokens}[$left..$right])));
            $right = ($left > 0) ? $dynamicRight[$left - 1] : -1;
        }

        # Append the matches
        push(@alignments, @matches);
    }

    # Return the output
    return \@alignments;
}

# Overlaps?
sub overlaps {
    my ($this, $sectionHash,
        $useContributors, $minOverlap) = @_;

    # Overlap with every SCU
    foreach my $scu ($this->getSCUs()) {
        my ($overlap, $leftMost, $text) =
            $scu->getLeftmostOverlap($sectionHash,
                                     $useContributors);
        if ($overlap >= $minOverlap) {
            # Match!
            return ($scu->getScore(), $leftMost, $scu, $overlap, $text);
        }
    }

    return (-1, -1, undef, undef, undef);
}

# Greedy align summary
sub greedyAlignSummary {
    my ($this, $summary, $minOverlap, $useContributors) = @_;

    # Output
    my @alignments = ();

    my $sentCounter;
    foreach my $sentence ($summary->getSentences()) {
        # One more sentence
        ++$sentCounter;

        my ($tokens, $words) = @{$sentence};
        my @matches;

        my %sectionHash = ();

        my ($start,  $end)   = (0, 0);
        while ($end < @{$tokens}) {
            # DEBUG
            # print STDERR "$start - $end\n";

            # If nothing is added, nothing will be won
            next if !defined($words->[$end]);

            # If it already exists, trim to the right
            if (exists($sectionHash{$words->[$end]})) {
                $sectionHash{$words->[$end]} = $end;
                next;
            }

            # Add it
            $sectionHash{$words->[$end]} = $end;

            # Find if it overlaps
            if ($this->greedyOverlaps(\%sectionHash, $end, $sentCounter,
                                      $useContributors, $minOverlap,
                                      \@matches)) {
                # Move the section start
                $start = $end + 1;
                %sectionHash = ();
            }

        } continue {
            ++$end;
        }

        # Append the alignments
        map { $_->setMyText($tokens) } @matches;
        push(@alignments, @matches);
    }

    # Return the output
    return \@alignments;
}

# Overlaps greedily?
# Overloaded by children
sub greedyOverlaps {
    my ($this, $sectionHash, $end, $sentCounter,
        $useContributors, $minOverlap, $matches) = @_;

    # Overlap with every SCU
    foreach my $scu ($this->getSCUs()) {
        my ($overlap, $leftMost, $text) =
            $scu->getLeftmostOverlap($sectionHash,
                                     $useContributors);
        if ($overlap >= $minOverlap) {
            # Match!
            push(@{$matches},
                 new Alignment($sentCounter, $leftMost, $end,
                               $overlap, $scu->getLabel(),
                               $scu->getUid(), $scu->getScore(),
                               $scu->getScore(), $text));

            # OK!
            return 1;
        }
    }

    # No overlap
    return;
}

# Get SCUs
sub getSCUs { return @{$_[0]->[0]}; }

# Return true
1;
