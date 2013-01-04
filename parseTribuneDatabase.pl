#!/usr/bin/perl

#
# parseTribuneDatabase.pl
#
# parse Tribune database XML into tab-delimited text file
#
# version 0
# created 2013-01-03
# modified 2013-01-03
#

use strict;
use Getopt::Long;

my ( $input_param, $output_param, $debug_param, $help_param, $version_param );
my ( $result, $xml_file, $file_size );

GetOptions(	'input|i=s'		=>	\$input_param,
			'output|o=s'	=>	\$output_param,
			'debug'			=>	\$debug_param,
			'help|?'		=>	\$help_param,
			'version'		=>	\$version_param );

if ( $debug_param ) {
	print "DEBUG: passed parameters:\n";
	print "input_param: $input_param\n";
	print "output_param: $output_param\n";
	print "debug_param: $debug_param\n";
	print "help_param: $help_param\n\n";
}

if ( $version_param ) {
	print "parseTribuneDatabase.pl version 0\n";
	exit;
}

if ( $help_param ) {
	print "parsecatalog.pl\n\n";
	print "version 0\n\n";
	print "--input <filename>\n";
	print "\tfile to process (required)\n";
	print "--output <filename>\n";
	print "\tif omitted, will be input file name with .csv extension\n";
	print "--help | -?\n";
	print "\tdisplay this text\n";
	print "--version\n";
	print "\tdisplay version information\n";
	exit;
}

# if no input file is specified, grab the first command line parameter and use that
if ( $input_param eq undef ) { $input_param = $ARGV[0]; }

if ( $output_param eq undef ) {
	$output_param = $input_param;
	$output_param =~ s/\.(.+)$//;
	$output_param .= ".csv"
}

if ( $debug_param ) {
	print "DEBUG: passed parameters:\n";
	print "input_param: $input_param\n";
	print "output_param: $output_param\n";
	print "debug_param: $debug_param\n";
	print "help_param: $help_param\n\n";
}

if ( $debug_param ) { print "DEBUG: opening input file $input_param\n"; }
open( INPUT_FILE, "<", $input_param )
	or die "Can't open input file $input_param\n";

$file_size = -s INPUT_FILE;
if ( $debug_param ) { print "DEBUG: input file $input_param is $file_size bytes\n"; }

if ( $debug_param ) { print "DEBUG: opening output file $output_param\n"; }
open( OUTPUT_FILE, ">", $output_param )
	or die "Can't create output file $output_param\n";

$result = read( INPUT_FILE, $xml_file, $file_size );
### do some error checking here

# output the header row
print OUTPUT_FILE "TMSId\t" .
					"altFilmId\t" .
					"rootId\t" .
					"connectorId\t" .
					"title\n";

##### update header row as we figure out the right fields to use

## here is where we parse the feed

my ( $program, $program_attributes );
my ( $TMSId, $altFilmId, $rootId, $versionId, $connectorId );
my ( $titles, $title, $title_attributes, $title_size, $title_type, $title_lang, $title_text );


while ( $xml_file =~ m/<program (.*?)>(.*?)<\/program>/gms ) {
	$program_attributes = $1;
	$program = $2;
	
#	if ( $debug_param ) { print "DEBUG: program attributes: $program_attributes\n"; }
	
	# get the various IDs from the program tag attributes
	if ( $program_attributes =~ m/TMSId="(.*?)"/ ) { $TMSId = $1; }
		else { $TMSId = ""; }
	if ( $program_attributes =~ m/altFilmId="(.*?)"/ ) { $altFilmId = $1; }
		else { $altFilmId = ""; }
	if ( $program_attributes =~ m/rootId="(.*?)"/ ) { $rootId = $1; }
		else { $rootId = ""; }
	if ( $program_attributes =~ m/connectorId="(.*?)"/ ) { $connectorId = $1; }
		else { $connectorId = ""; }
	
#	if ( $debug_param ) { print "DEBUG: TMS ID: $TMSId\n"; }
#	if ( $debug_param ) { print "DEBUG: altFilm ID: $altFilmId\n"; }
#	if ( $debug_param ) { print "DEBUG: root ID: $rootId\n"; }
#	if ( $debug_param ) { print "DEBUG: connector ID: $connectorId\n"; }
	
	# get the titles tag
	if ( $program =~ m/<titles>(.*?)<\/titles>/ms ) {
		$titles = $1;
		
		### there may be more than one <title>
		### we want the one where type="full"
		
		$title_text = "";
		while ( $titles =~ m/<title (.*?)>(.*?)<\/title>/gms ) {
			$title_attributes = $1;
			$title = $2;
			if ( $title_attributes =~ m/type="full"/ ) { $title_text = $title; }
		}
		
#		if ( $debug_param ) { print "DEBUG: Title Attributes: $title_attributes\n"; }
		if ( $debug_param ) { print "DEBUG: Title: $title_text\n"; }

	}
	
	
	print OUTPUT_FILE "$TMSId\t" .
						"$altFilmId\t" .
						"$rootId\t" .
						"$connectorId\t" .
						"$title\n";
			
}





### XML fields
# TMSId
# altFilmId
# rootId
# versionId
# connectorId

# titles
# title
# title size
# title type			<- we want "full"
# title lang
# title text			<- this is the actual title

# descriptions
# description
# description size		<- we want largest value - 500? 250?
# description type		<- we want "plot"
# description lang
# description text

# cast
# member
# personId
# ord
# role					<- we want "Actor"
# characterName
# name
# name nameId
# name first
# name last
### use first x cast members
### put the names into a comma-delimited list in a single column

# crew
# member
# personId
# ord
# role					<- we want "Director"
# name
# name nameId
# name first
# name last
### if there is more than one director, put each into a comma-delimited list in a single column

# runTime

# progType

# holiday
# holidayId
# text

# countries
# country

# awards
# award
# award won
# award name
# award name awardId
# award name text
# award category
# award category awardCatId
# award category text
# award year
# award recipient
# award recipient nameId
# award recipient text

# genres
# genre
# genre genreId
# genre text
### if there are more than one genre, make a comma-delimited list in a single column

# ratings
### there are multiple ratings types that can show up here
# qualityRating
# qualityRating ratingsBody
# qualityrating value
# advisories
# advisory
# advisory text
# rating
# rating area				<- we want "United States"
# rating code
# rating description
# rating ratingsBody
# rating text

# colorCode

# movieInfo
# movieInfo releases
# movieInfo release
# movieInfo release type	<- we want "Year" or "Original"
# movieInfo release date
# movieInfo release distributors
# movieInfo release distributors name
# movieInfo release distributors country
# movieInfo soundMixes
# movieInfo soundMix
# movieInfo pictureFormats
# movieInfo pictureFormat
# movieInfo productionCompanies
# movieInfo productionCompanies name

# images
# image
# image type
# image width
# image height
# image primary
# image category
# image URI
# image caption

# animation

# origAudioLang





sub trim($) {
	my $myString = shift;
	$myString =~ s/^\s+//;	# trim any leading whitespace
	$myString =~ s/\s+$//;	# trim any trailing whitespace
	return( $myString );
}

sub unescape($) {
	my $myString = shift;
	$myString =~ s/&amp;/&/g;	# replace any &amp; with &
	$myString =~ s/&lt;/</g;	# replace any &lt; with <
	$myString =~ s/&gt;/>/g;	# replace any &gt; with >
	return( $myString );
}
