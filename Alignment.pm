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

package Alignment;

# Constructor
# Attributes
# - Sentence
# - Left
# - Right
# - Overlap
# - Label
# - Uid
# - Score
# - Increment
# - Ref Text
# - My Text
sub new {
    my ($class, @attributes) = @_;

    return bless(\@attributes, $class);
}


# Set my text
sub setMyText {
    my ($this, $tokens) = @_;

    $this->[9] = join(' ', @{$tokens}[$this->[1]..$this->[2]]);
}


# Consultor Functions
sub getSentNumber { return $_[0]->[0]; }
sub getLeft       { return $_[0]->[1]; }
sub getRight      { return $_[0]->[2]; }
sub getOverlap    { return $_[0]->[3]; }
sub getLabel      { return $_[0]->[4]; }
sub getUid        { return $_[0]->[5]; }
sub getScore      { return $_[0]->[6]; }
sub getIncrement  { return $_[0]->[7]; }
sub getRefText    { return $_[0]->[8]; }
sub getMyText     { return $_[0]->[9]; }


# Return true
1;
