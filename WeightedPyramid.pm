# Copyright (C)  Edgar Gonzàlez i Pellicer
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

use strict;

use Pyramid;
use Alignment;

# Weighted Pyramid contents
package WeightedPyramid;
our @ISA = qw( Pyramid );

# Sorting function
sub _sortingFunction {
    # Score * (length - 1) + Score / 10
    return $b->[0] <=> $a->[0] if $b->[0] != $a->[0];

    # Score
    return $b->[1] <=> $a->[1];
}

# Constructor
sub new {
    my ($class, $file, %options) = @_;

    # Meet the parents...
    my $this = Pyramid::new($class, $file, %options);

    # Find the list of contributions and labels of each SCU
    my @superList = ();
    foreach my $scu ($this->getSCUs()) {
	# SCU Score
	my $scuScore = $scu->getScore();

	# Label
	my $words = $scu->getLabelWords();
	my $score = $scuScore * (@{$words} - 1) + 0.1 * $scuScore;
	push(@superList, [ $score, $scuScore, $words,
			   $scu, $scu->getLabel() ]);

	# Use contributors?
	next unless $options{'contrib'};

	# Every contributor
	foreach my $contrib ($scu->getContributors()) {
	    $score = $scuScore * (@{$contrib} - 1) + 0.1 * $scuScore;
	    push(@superList, [ $score, $scuScore, $contrib->[0],
			       $scu, $contrib->[1] ]);
	}
    }

    # Sort the superlist
    @superList = sort _sortingFunction (@superList);

    # Add it to the object
    push(@{$this}, \@superList);

    # Return the object
    return $this;
}


# Overlaps?
# Overloaded from parent
sub overlaps {
    my ($this, $sectionHash,
	$useContributors, $minOverlap) = @_;

    # Overlap with every superElement
    foreach my $superElem ($this->getSuperList()) {
	my ($overlap, $leftMost) =
	  SCU::_getLeftmostOverlap($superElem->[2],
				   $sectionHash);
	if ($overlap >= $minOverlap) {
	    # Match!
	    return ($superElem->[0], $leftMost, $superElem->[3],
		    $overlap, $superElem->[4]);
	}
    }
    
    # No overlap
    return (-1, -1, undef, undef, undef);
}


# Overlaps greedily?
# Overloaded from parent
sub greedyOverlaps {
    my ($this, $sectionHash, $end, $sentCounter,
	$useContributors, $minOverlap, $matches) = @_;
	
    # Overlap with every superElement
    foreach my $superElem ($this->getSuperList()) {
	my ($overlap, $leftMost) =
	  SCU::_getLeftmostOverlap($superElem->[2],
				   $sectionHash);
	if ($overlap >= $minOverlap) {
	    # Match!
	    my $scu = $superElem->[3];
	    push(@{$matches},
		 new Alignment($sentCounter, $leftMost, $end,
			       $overlap, $scu->getLabel(),
			       $scu->getUid(), $scu->getScore(),
			       $superElem->[0], $superElem->[4]));
	    
	    # OK!
	    return 1;
	}
    }

    # No overlap
    return;
}


# Get Superlist
sub getSuperList { return @{$_[0]->[1]}; }


# Return true
1;
