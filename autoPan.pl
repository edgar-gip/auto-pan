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

use Getopt::Long;

use EngTok;
use Porter;

use Pyramid;
use Summary;
use WeightedPyramid;
use Writer;

# Help string
my $helpString = << "EOF;";

Usage:
    $0 [options] <pyramidFile> <summaryFile>

Options:
    --lower
    --nolower
      Lower-case or not words
      (Default is yes)

    --stop
    --nostop
      Remove or not stop words
      (Default is yes)

    --stem
    --nostem
      Stem words. Implies --lower and --stop.
      (Default is yes)

    --stop-word-file <file>
      Stop word file.
      (Default is stopwords/empty.en)

    --min-overlap <fraction>
      Minimum required overlap.
      (Default is 0.9)

    --use-contributors
    --nouse-contributors
      Use or not contributors for overlap.
      (Default is yes)

    --min-contributor-length <length>
      Minimum contributor length
      (Default is 2)

    --length-weighting
    --nolength-weighting
      Use or not length weighting.
      (Default is yes)

    --greedy-alignment
    --nogreedy-alignment
      Use or not a greedy alignment strategy.
      (Default is not)

    --output-format=pln
    --output-format=pan
      Output format is plain (pln) or XML (pan)
      (Default is pln)

    --help
      Show this help

EOF;

# Options
my $lower           = 1;
my $stop            = 1;
my $stem            = 1;
my $stopWordFile    = 'stopwords/empty.en';
my $minOverlap      = 0.9;
my $useContributors = 1;
my $minContriLength = 2;
my $lengthWeighting = 1;
my $greedyAlignment;
my $outputFormat    = 'pln';
my $help;

# Get the options
if (!GetOptions('lower!'                   => \$lower,
		'stop!'                    => \$stop,
		'stem!'                    => \$stem,
		'stop-word-file=s'         => \$stopWordFile,
		'min-overlap=f'            => \$minOverlap,
		'use-contributors!'        => \$useContributors,
		'min-contributor-length=i' => \$minContriLength,
		'length-weighting!'        => \$lengthWeighting,
		'greedy-alignment!'        => \$greedyAlignment,
		'output-format=s'          => \$outputFormat,
	        'help'                     => \$help) ||
    $help || @ARGV != 2) {
    die $helpString;
}

# Get the parameters
my ($pyramidFile, $summaryFile) = @ARGV;

# Check the format
$outputFormat = lc($outputFormat);
die $helpString if $outputFormat !~ /^(pln|pan)$/;

# Create the stemmer and tokenizer
my $stemmer   = new Porter($stopWordFile);
my $tokenizer = new EngTok();

# Create a writer
my $writer = $outputFormat eq 'pan' ? new XMLWriter() : new PlainWriter();

# Create the options object
my %options = ( 'lower'     => $lower,
		'stop'      => $stop,
		'stem'      => $stem,
		'contrib'   => $useContributors,
		'mincontri' => $minContriLength,
		'stemmer'   => $stemmer,
		'tokenizer' => $tokenizer,
		'writer'    => $writer );

# Write the header
$writer->printHeader();

# Load the pyramid
my $pyramid = $lengthWeighting ?
    new WeightedPyramid($pyramidFile, %options) :
    new Pyramid($pyramidFile, %options);

# Write the middle sequence
$writer->printMiddle();

# Load the summary
my $summary = new Summary($summaryFile, %options);

# Print the summary
$writer->printSummary($summary);

# Align
my $alignment;
if ($greedyAlignment) {
    $alignment =
	$pyramid->greedyAlignSummary($summary, $minOverlap, $useContributors);
} else {
    $alignment =
	$pyramid->alignSummary($summary, $minOverlap, $useContributors);
}

# Print the alignment
$writer->printAlignment($alignment, $summary, $pyramid);

# Print the footer
$writer->printFooter();

# That's all
exit(0);

