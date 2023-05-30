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


#########################################
# Abstract class, mother of all writers #
# not including Kafka, Proust nor Joyce #
#########################################
package Writer;

# Constructor
# -> Empty object
sub new {
    my ($class) = @_;

    return bless([], $class);
}

# Functions to be overloaded
sub printHeader    {}
sub printPyramid   {}
sub printMiddle    {}
sub printSummary   {}
sub printAlignment {}
sub printFooter    {}


################
# Plain Writer #
################

package PlainWriter;
our @ISA = qw( Writer );

# Print the alignment
sub printAlignment {
    my ($this, $alignment, $summary, $pyramid) = @_;

    # Foreach match
    foreach my $match (@{$alignment}) {
        print("Sentence $match->[0]:\n",
              "$match->[3] with SCU $match->[5] ",
              "(Sc $match->[6] / $match->[7]): $match->[4]\n",
              " \[ $match->[8] \]\n",
              " $match->[1]..$match->[2]: $match->[9]\n\n");
    }
}


##############
# XML Writer #
##############

package XMLWriter;
our @ISA = qw( Writer );

# Print the XML Header
sub printHeader {
    print << 'EOH;';
<?xml version="1.0"?>
<!DOCTYPE peerAnnotation [
 <!ELEMENT peerAnnotation (pyramid,annotation)>
 <!ELEMENT annotation (text,peerscu+)>
 <!ELEMENT peerscu (contributor)*>
 <!ATTLIST peerscu uid CDATA #REQUIRED
             label CDATA #REQUIRED>
 <!ELEMENT pyramid (text,scu*)>
 <!ATTLIST pyramid numModels CDATA "0">
 <!ELEMENT text (line*)>
 <!ELEMENT line (#PCDATA)>
 <!ELEMENT scu (contributor)+>
 <!ATTLIST scu uid CDATA #REQUIRED
            label CDATA #REQUIRED>
 <!ELEMENT contributor (part)+>
 <!ATTLIST contributor label CDATA #REQUIRED>
 <!ELEMENT part EMPTY>
 <!ATTLIST part label CDATA #REQUIRED
                start CDATA #REQUIRED
                end   CDATA #REQUIRED>

]>

<peerAnnotation>
EOH;
}


# Print the Pyramid
sub printPyramid {
    my ($this, $tree) = @_;

    dumpPyramidXML(@{$tree});
}


# Print the XML Middle
sub printMiddle {
    print "\n<annotation>\n";
}


# Print the summary
sub printSummary {
    my ($this, $summary) = @_;

    print "  <text>\n";
    foreach my $line (@{$summary}) {
        # print "    <line>$line->[2]</line>\n";
        print "    <line>", escapeXML(join(' ', @{$line->[0]})), "</line>\n";
    }
    print "  </text>\n";
}


# Print the alignment
sub printAlignment {
    my ($this, $alignment, $summary, $pyramid) = @_;

    # Contributors uid
    my %contributors;

    # Offset in the document
    my $offset = 0;

    # Match pointer
    my $curMatch = 0;

    # Foreach line
    for (my $nLine = 0; $nLine < @{$summary}; ++$nLine) {
        my $line = $summary->[$nLine];

        my $endOffset = $offset +
            length(join(' ', @{$line->[0]}));
        my $curWord = 0;

        while ($curMatch < @{$alignment} &&
               $alignment->[$curMatch]->getSentNumber() == $nLine + 1) {
            # Match
            my $match = $alignment->[$curMatch];

            # Left and right
            my $left  = $match->getLeft();
            my $right = $match->getRight();

            # If left is not the current, add an unmatched SCU
            if ($curWord < $left) {
                my $text = join(' ', @{$line->[0]}[$curWord..$left-1]);
                my $newOffset = $offset + length($text);
                push(@{$contributors{0}},
                     [ $text, $offset, $newOffset ]);
                $offset = $newOffset + 1;
            }

            # Add this SCU
            my $text = $match->getMyText();
            # join(' ', @{$line->[0]}[$left..$right]);
            my $newOffset = $offset + length($text);
            push(@{$contributors{$match->getUid()}},
                 [ $text, $offset, $newOffset ]);
            ++$newOffset unless $right == $#{$line->[0]};
            $offset  = $newOffset;
            $curWord = $right + 1;

            # Next match
            ++$curMatch;
        }

        if ($offset < $endOffset) {
            # Add an unmatched SCU
            push(@{$contributors{0}},
                 [ join(' ', @{$line->[0]}[$curWord..$#{$line->[0]}]),
                   $offset,
                   $endOffset ]);
            $offset = $endOffset;
        }

        # Add the newline character
        ++$offset;
    }

    # Output
    foreach my $scu ($pyramid->getSCUs()) {
        print ('  <peerscu uid="', $scu->getUid(),
               '" label="(', $scu->getScore(),
               ') ', escapeXML($scu->getLabel()), "\">\n");

        if ($contributors{$scu->getUid()}) {
            foreach my $contrib (@{$contributors{$scu->getUid()}}) {
                print "    <contributor label=\"",escapeXML($contrib->[0]),"\">\n";
                print "      <part label=\"",escapeXML($contrib->[0]),"\" start=\"$contrib->[1]\" end=\"$contrib->[2]\"/>\n";
                print "    </contributor>\n";
            }
        }
        print "  </peerscu>\n";
    }

    # The 0 SCU
    print '  <peerscu uid="0" label="All non-matching SCUs go here">', "\n";
    if ($contributors{0}) {
        foreach my $contrib (@{$contributors{0}}) {
            print "    <contributor label=\"",escapeXML($contrib->[0]),"\">\n";
            print "      <part label=\"",escapeXML($contrib->[0]),"\" start=\"$contrib->[1]\" end=\"$contrib->[2]\"/>\n";
#           print "      <part label=\"$contrib->[0]\" start=\"0\" end=\"10\"/>\n";
            print "    </contributor>\n";
        }
    }
    print "  </peerscu>\n";
}


# Print the Footer
sub printFooter {
    print "</annotation>\n</peerAnnotation>\n";
}


# Dump XML Helper function
sub dumpPyramidXML {
    my ($tag, $content) = @_;

    if ($tag eq '0') {
        # Text
        print escapeXML($content);

    } elsif ($tag eq 'part') {
        # Empty tag
        print "<part";
        map {
            print " $_ = \"",escapeXML($content->[0]{$_}),"\"";
        } keys(%{$content->[0]});
        print "/>";

    } else {
        # Filled Tag
        print "<$tag";
        map {
            print " $_ = \"",escapeXML($content->[0]{$_}),"\"";
        } keys(%{$content->[0]});
        print ">";

        # Call
        for (my $i = 1; $i < @{$content}; $i += 2) {
            dumpPyramidXML($content->[$i], $content->[$i + 1]);
        }

        # Close
        print "</$tag>";
    }
}


# Escape XML characters
sub escapeXML {
    my ($string) = @_;

    $string =~ s/\&/&amp;/g;
    $string =~ s/\"/&quot;/g;
    $string =~ s/\</&lt;/g;

    return $string;
}


# Return true
1;
