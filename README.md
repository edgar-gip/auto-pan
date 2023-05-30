# AutoPan

_Automatic Peer Annotator_ \
Edgar Gonzàlez i Pellicer, Maria Fuentes Fort, 2005

## Description

**AutoPan** is a tool that helps in the evaluation of Automatic Summaries.

A description of the tool can be found in Fuentes et al. (2005)

> In DUC 2001 to 2004, the manual evaluation was based on comparison with a single human-written
> model and a lot of the information of evaluated summaries (both human and automatic), was marked
> as "related to the topic, but not directly expressed in the model summary". The pyramid method
> (proposed by Nenkova and Passoneau (2004)) addresses the problem by using multiple human summaries
> to create a gold-standard and by exploiting the frequency of information in the human summaries in
> order to assign importance to different facts.
>
> However, the method of pyramids for evaluation requires a human annotator to match fragments of
> text in the system summaries to the SCUs in the pyramids. We have tried to automate this part of
> the process.
>
> - The text in the SCU label and all its contributors is stemmed and stop words are removed,
>   obtaining a set of stem vectors for each SCU. The system summary text is also stemmed and freed
>   from stop words.
>
> - A search for non-overlaping windows of text which can match SCUs is carried. A window and an SCU
>   can match if a fraction higher than a threshold (experimentally set to 0.90) of the stems in the
>   label or some of the contributors of the SCU are present in the window, without regarding order.
>   Each match is scored taking into account the score of the SCU as well as the number of matching
>   stems. The solution which globally maximizes the sum of scores of all matches is found using
>   dynamic programming techniques.
>
> The constituent annotations automatically produced are scored using the same metrics as for manual
> annotations, and it is found that there is statistical evidence supporting the hypothesis that the
> scores obtained by automatic annotations are correlated to the ones obtained by manual ones for
> the same system and summary.

**AutoPan** is this tool that takes a pyramid file and a summary and produces the peer annotation
file that afterwards can be evaluated using the software provided by DUC.

## References

- Maria **Fuentes**, Edgar **Gonzàlez**, Daniel **Ferrés**, Horacio **Rodríguez** \
  _QASUM-TALP at DUC 2005 Automatically Evaluated with the Pyramid based Metric AutoPan_ \
   DUC Evaluation Campaign, 2005

- Ani **Nenkova**, Rebecca **Passonneau** \
  _Evaluating content selection in summarization: The pyramid method_ \
  Proceedings of HLT/NAACL, 2004

## Requirements

To run **AutoPan** you need:

- `Perl` 5.6.0 or greater \
  Available at [Perl](http://www.perl.com/) \
  The version used in development was 5.8.4

- `XML::Parser` Perl Module \
  Available at [CPAN](http://search.cpan.org/~msergeant/XML-Parser-2.34/) \
  The version used in development was 2.34

- `Expat` Library \
  Available at [SourceForge](http://expat.sourceforge.net/) \
  The version used in development was 1.95.8

## Download

**AutoPan** can be downloaded from its [GitHub page](https://github.com/edgar-gip/auto-pan). The
current version is `0.1.1`.

The code is available under the conditions of the [General Public License (GPL) v2.0](COPYING)

## Program Options

This is a more detailed explanation of the options than the one given by the program if invoked as:

```
perl autoPan.pl --help
```

### Usage

```
perl autoPan.pl [options] <pyramidFile> <summaryFile>
```

The `<pyramidFile>` must be an XML file following the format of DUC pyramid files. The
`<summaryFile>` must be a plain text file with a summary fragment in each line. No windows will
cross fragment boundaries.

Output is written through standard output.

### Options

`--lower` \
`--nolower` \
Lower-case or not words. \
(Default is yes) \
If words are lower-cased, they can match words with which they only differ in case, allowing for
more matches.

`--stop` \
`--nostop` \
Remove or not stop words. \
(Default is yes) \
If stop words are removed, the matching between windows and contributors does not take them into
account.

`--stem` \
`--nostem` \
Stem words. Implies `--lower` and `--stop`. \
(Default is yes) \
If stemming is applied, words from the same root (such as construct, constructed, construction...)
can match. We use as stemmer the Porter Stemmer for English.

`--stop-word-file <file>` \
Stop word file. \
(Default is `stopwords/empty.en`) \
Allow the selection of a list of stop words. This file must be a text file with each word in a line
by itself.

`--min-overlap <fraction>` \
Minimum required overlap. \
(Default is `0.9`) \
Selects the fraction of the words in the contributor that should be matched by those in a window to
consider that window and contributor match.

`--use-contributors` \
`--nouse-contributors` \
Use or not contributors for overlap. \
(Default is yes) \
If this option is disabled, only the SCU label is used as reference. If set, both the label and the
contributors are used.

`--min-contributor-length <length>` \
Minimum contributor length \
(Default is `2`) \
The minimum number of words (removing stop words) a contributor must have to allow matchings against
it.

`--length-weighting` \
`--nolength-weighting` \
Use or not length weighting. \
(Default is yes) ` \
If this option is set, the score of a match takes into account the length of the contributor, as
well as the score of the SCU. If unset, only the score of a match equals the SCU score.

`--greedy-alignment` \
`--nogreedy-alignment` \
Use or not a greedy alignment strategy. \
(Default is not) \
Determines if the matching is performed in a greedy way or on the contrary the globally best
solution is searched.

`--output-format=pln` \
`--output-format=pan` \
Output format is plain (pln) or XML (pan) \
(Default is `pln`) \
Determines if the output is a XML PAN file, according to the format in DUC, or in the contrary it is
a plain text output, with information about matches and scores useful for development.

`--help` \
Show this help \
Just shows the help

## Acknowledgements

This work has been supported by the European Comission (CHIL, IST-2004-506909), the Ministry of
Universities, Research and Information Society (DURSI) of the Catalan Government, and the European
Social Fund. The research group, TALP Research Center, is recognized as a Quality Research Group
(2001 SGR 00254) by DURSI.

We would like to thank Martin Porter and Erik Tjong Kim Sang for allowing us to use their code in
our tool.

## Contact

For help, suggestions or bug reports, use the [GitHub page](https://github.com/edgar-gip/auto-pan).
