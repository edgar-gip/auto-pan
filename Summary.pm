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

use IO::File;

use SCU;

# Summary object
package Summary;

# Constructor
sub new {
    my ($class, $file, %options) = @_;

    my $fin = new IO::File("< $file")
        or die "Can't Open Summary File $file\n";

    # Object
    my $this = [];

    # Add every sentence
    my $line;
    while ($line = $fin->getline()) {
        chomp($line);

        # Process
        my ($tokens, $words) = processString($line, \%options);
        # push(@{$this}, [ $tokens, $words, $line ]) if @{$tokens};
        push(@{$this}, [ $tokens, $words ]) if @{$tokens};
    }
    $fin->close();

    # Return the object
    return bless($this, $class);
}

# Process the string
sub processString {
    my ($string, $options) = @_;

    # Tokenize
    my @words  = $options->{'tokenizer'}->tokenizeString($string);
    my @tokens = @words;

    # Lower case and stem
    if ($options->{'stem'}) {
        @words = map {
            my $stem = $options->{'stemmer'}->stem($_);
            $stem ? $stem : undef;
        } @words;

    } elsif ($options->{'lower'}) {
        @words = map { lc($_) } @words;
        if ($options->{'stop'}) {
            @words = map {
                $options->{'stemmer'}->isStopWord($_) ? undef : $_;
            } @words;
        } else {
            @words = map {
                $options->{'stemmer'}->isNonWord($_) ? undef : $_;
            } @words;
        }

    } elsif ($options->{'stop'}) {
        @words = map {
            $options->{'stemmer'}->isStopWord(lc($_)) ? undef : $_;
        } @words;

    } else {
        @words = grep {
            $options->{'stemmer'}->isNonWord($_) ? undef : $_;
        } @words;
    }

    # Return
    return (\@tokens, \@words);
}

# Get the sentences
sub getSentences { return @{$_[0]}; }

# Return true
1;
