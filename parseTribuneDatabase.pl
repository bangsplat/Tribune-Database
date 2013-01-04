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
my ( $program, $program_attributes );
my ( $TMSId, $altFilmId, $rootId, $versionId, $connectorId );
my ( $titles, $title, $title_attributes, $title_size, $title_type, $title_lang, $title_text );
my ( $descriptions, $description, $description_attributes, $longest_description_length, $longest_description );
my ( $description_size, $description_type, $description_lang, $description_text );
my ( $cast, $cast_member, $cast_member_attributes, $cast_person_id, $cast_ord, $cast_role );
my ( $cast_character_name, $cast_name, $cast_name_first, $cast_name_last, $cast_list );
my ( $director_list, $crew, $crew_member, $crew_member_attributes, $crew_member_role );
my ( $crew_member_name, $crew_member_name_attributes, $crew_member_name_id );
my ( $crew_member_person_id, $crew_member_ord, $crew_member_role );
my ( $crew_member_name_id, $crew_member_name_first, $crew_member_name_last );
my ( $runtime, $progtype );
my ( $holiday, $holiday_id, $holiday_text );
my ( $countries, $country, $country_list );
my ( $genres, $genre, $genre_id, $genre_text, $genre_list );
my ( $ratings );
my ( $advisories, $advisory, $advisory_list );
my ( $rating, $rating_area, $rating_code, $rating_description, $rating_body, $rating_text );
my ( $quality_rating_body, $quality_rating );
my ( $color_code );
	

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

close( INPUT_FILE );

# output the header row
print OUTPUT_FILE "TMSId\t" .
					"altFilmId\t" .
					"rootId\t" .
					"connectorId\t" .
					"title\t" .
					"description\t" .
					"cast\t" .
					"director\t" .
					"runtime\t" .
					"progtype\t" .
					"holiday\t" .
					"countries\t" .
					"genres\t" .
					"advisories\t" .
					"rating (US)\t" .
					"qualityRating\t" .
					"color code\n";

##### update header row as we figure out the right fields to use

## here is where we parse the feed

while ( $xml_file =~ m/<program (.*?)>(.*?)<\/program>/gms ) {
	$program_attributes = trim( $1 );
	$program = trim( $2 );
	
	# get the various IDs from the program tag attributes
	if ( $program_attributes =~ m/TMSId="(.*?)"/ ) { $TMSId = trim( $1 ); }
		else { $TMSId = ""; }
	if ( $program_attributes =~ m/altFilmId="(.*?)"/ ) { $altFilmId = trim( $1 ); }
		else { $altFilmId = ""; }
	if ( $program_attributes =~ m/rootId="(.*?)"/ ) { $rootId = trim( $1 ); }
		else { $rootId = ""; }
	if ( $program_attributes =~ m/connectorId="(.*?)"/ ) { $connectorId = trim( $1 ); }
		else { $connectorId = ""; }
	
	# get the titles tag
	if ( $program =~ m/<titles>(.*?)<\/titles>/ms ) {
		$titles = trim( $1 );
		
		# there may be more than one <title>
		# we want the one where type="full"
		
		$title_text = "";
		while ( $titles =~ m/<title (.*?)>(.*?)<\/title>/gms ) {
			$title_attributes = trim( $1 );
			$title = trim( $2 );
			if ( $title_attributes =~ m/type="full"/ ) { $title_text = unescape( $title ); }
		}
	}
	
	#  get the descriptions tag
	if ( $program =~ m/<descriptions>(.*?)<\/descriptions>/ms ) {
		$descriptions = trim( $1 );
		
		# there may be more than one description
		# we want the longest one with type="plot"
		
		$longest_description = "";
		$longest_description_length = 0;
		
		while ( $descriptions =~ m/<desc (.*?)>(.*?)<\/desc>/gms ) {
			$description_attributes = trim( $1 );
			$description = trim( $2 );
			
			if ( $description_attributes =~ m/size="(.*?)"/ ) { $description_size = trim( $1 ); }
				else { $description_size = ""; }
			if ( $description_attributes =~ m/type="(.*?)"/ ) { $description_type = trim( $1 ); }
				else { $description_type = ""; }
			if ( $description_attributes =~ m/lang="(.*?)"/ ) { $description_lang = trim( $1 ); }
				else { $description_lang = ""; }
			
			if ( ( $description_type eq "plot" ) && ( $description_size > $longest_description_length ) ) {
				$longest_description = $description;
				$longest_description_length = $description_size;
			}
		}
		$description_text = unescape( $longest_description );
	}
	
	# get the cast tag
	$cast_list = "";
	if ( $program =~ m/<cast>(.*?)<\/cast>/ms ) {
		$cast = trim( $1 );
		while ( $cast =~ m/<member (.*?)>(.*?)<\/member>/gms ) {
			$cast_member_attributes = trim( $1 );
			$cast_member = trim( $2 );
			
			if ( $cast_member_attributes =~ m/personId="(.*?)"/ ) { $cast_person_id = trim( $1 ); }
				else { $cast_person_id = ""; }
			if ( $cast_member_attributes =~ m/ord="(.*?)"/ ) { $cast_ord = trim( $1 ); }
				else { $cast_ord = ""; }
			
			### character name?
			
			if ( $cast_member =~ m/<name (.*?)>(.*?)<\/name>/ms ) {
				$cast_person_id = trim( $1 );		### not strictly correct, but I'm not going to use this
				$cast_name = trim( $2 );
				
				if ( $cast_name =~ m/<first>(.*?)<\/first>/ ) { $cast_name_first = unescape( trim( $1 ) ); }
					else { $cast_name_first = ""; }
				if ( $cast_name =~ m/<last>(.*?)<\/last>/ ) { $cast_name_last = unescape( trim( $1 ) ); }
					else { $cast_name_last = ""; }
				
				if ( $cast_list ne "" ) { $cast_list .= ", "; }
				$cast_list .= "$cast_name_first $cast_name_last";
			}
		}
	}
		
	# get crew tag
	$director_list = "";
	if ( $program =~ m/<crew>(.*?)<\/crew>/ms ) {
		$crew = trim( $1 );
		while ( $crew =~ m/<member (.*?)>(.*?)<\/member>/gms ) {
			$crew_member_attributes = trim( $1 );
			$crew_member = trim( $2 );
			
			if ( $crew_member_attributes =~ m/personId="(.*?)"/ ) { $crew_member_person_id = trim( $1 ); }
				else { $crew_member_person_id = ""; }
			if ( $crew_member_attributes =~ m/ord="(.*?)"/ ) { $crew_member_ord = trim( $1 ); }
				else { $crew_member_ord = ""; }
			
			if ( $crew_member =~ m/<role>(.*?)<\/role>/ ) { $crew_member_role = trim( $1 ); }
				else { $crew_member_role = ""; }
			
			if ( $crew_member =~ m/<name (.*?)>(.*?)<\/name>/ms ) {
				$crew_member_name_attributes = trim( $1 );
				$crew_member_name = trim( $2 );
				
				if ( $crew_member_name_attributes =~ m/nameId="(.*?)"/ ) {
					$crew_member_name_id = trim( $1 );
				} else { $crew_member_name_id = ""; }
			
				if ( $crew_member_name =~ m/<first>(.*?)<\/first>/ ) {
					$crew_member_name_first = unescape( trim( $1 ) );
				} else { $crew_member_name_first = ""; }
			
				if ( $crew_member_name =~ m/<last>(.*?)<\/last>/ ) {
					$crew_member_name_last = unescape( trim( $1 ) );
				} else { $crew_member_name_last = ""; }
				
				if ( $crew_member_role eq "Director" ) {
					if ( $director_list ne "" ) { $director_list .= ", "; }
					$director_list .= "$crew_member_name_first $crew_member_name_last";
				}
			}
		}
	}
		
	# get runTime tag
	if ( $program =~ m/<runTime>(.*?)<\/runTime>/ ) { $runtime = trim( $1 ); }
		else { $runtime = ""; }
	
	# get progType tag
	if ( $program =~ m/<progType>(.*?)<\/progType>/ ) { $progtype = trim( $1 ); }
		else { $progtype = ""; }
	
	# get holiday tag
	$holiday_id = "";
	$holiday_text = "";
	# get holiday tag ???  do we need this???
	if ( $program =~ m/<holiday holidayId="(.*?)">(.*?)<\/holiday>/ ) {
		$holiday_id = $1;
		$holiday_text = $2;
	}
	
	# get countries tag
	# there can be more than one, so make a comma-delimited list
	$country_list = "";
	# get countries tag
	if ( $program =~ m/<countries>(.*?)<\/countries>/ms ) {
		$countries = trim( $1 );
		while( $countries =~ m/<country>(.*?)<\/country>/gms ) {
			$country = trim( $1 );
			if ( $country_list ne "" ) { $country_list .= ", "; }
			$country_list .= $country;
		}
	}
	
	# awards tag comes next
	# I'm not sure we need this and it's too complex for a single column
	
	# get genres tag	
	$genre_list = "";
	# get genres tag
	if ( $program =~ m/<genres>(.*?)<\/genres>/ms ) {
		$genres = trim( $1 );
		while ( $genres =~ m/<genre genreId="(.*?)">(.*?)<\/genre>/gms ) {
			$genre_id = trim( $1 );
			$genre_text = trim( $2 );
			if ( $genre_list ne "" ) { $genre_list .= ", "; }
			$genre_list .= $genre_text;
		}
	}
	
	# get ratings tag
	if ( $program =~ m/<ratings>(.*?)<\/ratings>/ms ) {
		$ratings = trim( $1 );

		# there are three sub-tags: advisories, rating, and qualityRating
		# they serve different purposes
		# make three separate columns
	
		# advisories
		$advisory_list = "";
		if ( $ratings =~ m/<advisories>(.*?)<\/advisories>/ms ) {
			$advisories = trim( $1 );
			while( $advisories =~ m/<advisory>(.*?)<\/advisory>/gms ) {
				$advisory = trim( $1 );
				if ( $advisory_list ne "" ) { $advisory_list .= ", "; }
				$advisory_list .= $advisory
			}
		}
		
		# rating
		# get the US rating for now
		# do we want to capture others as well?
		while ( $ratings =~ m/(<rating .*?>.*?<\/rating>)/gms ) {
			$rating = trim( $1 );
			if ( ( $rating =~ m/area="United States"/ms ) && ( $rating =~ m/code="(.*?)"/ms ) ) {
				$rating_code = $1;
			}
		}
		
		# qualityRating
		# this one is a little unusual - there is no value, so it's closed tag
		if ( $ratings =~ m/<qualityRating ratingsBody="(.*?)" value="(.*?)"\/>/ ) {
			$quality_rating_body = trim( $1 );
			$quality_rating = trim( $2 );
		} else { $quality_rating = ""; }
	}
	
	# get color code tag
	if ( $program =~ m/<colorCode>(.*?)<\/colorCode>/ms ) {
		$color_code = unescape( trim( $1 ) );
	} else { $color_code = ""; }
	
	# get movieInfo tag
	# this one can get complicated
	# there are multiple sub tags
	# 	releases
	#		multiple release types
	#			Year
	#			Original
	#			Wide
	#			others?
	#	soundMixes
	# 	pictureFormats
	# 	productionCompanies
	#		can be more than one





# <movieInfo>
# 	<releases>
#		 <release type="Year" date="1968"/>
#		 <release type="Original" date="1968-06-12">
#			 <distributors>
#				 <name>Paramount Pictures</name>
#			 </distributors>
# 			<country>USA</country>
# 		</release>
# 		<release type="Wide" date="1968-06-12">
# 			<distributors>
# 				<name>Paramount Pictures</name>
# 			</distributors>
# 			<country>USA</country>
# 		</release>
#	 </releases>
# 	<soundMixes>
# 		<soundMix>Mono</soundMix>
# 	</soundMixes>
# 	<pictureFormats>
# 		<pictureFormat>Flat (1.85:1)</pictureFormat>
# 	</pictureFormats>
# 	<productionCompanies>
# 		<name>Paramount Pictures</name>
# 	</productionCompanies>
# </movieInfo>
	
	


	
	print OUTPUT_FILE "$TMSId\t" .
						"$altFilmId\t" .
						"$rootId\t" .
						"$connectorId\t" .
						"$title_text\t" .
						"$description_text\t" .
						"$cast_list\t" .
						"$director_list\t" .
						"$runtime\t" .
						"$progtype\t" .
						"$holiday_text\t" .
						"$country_list\t" .
						"$genre_list\t" .
						"$advisory_list\t" .
						"$rating_code\t" .
						"$quality_rating\t" .
						"$color_code\n";
			
}

close( OUTPUT_FILE );


### XML fields

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
	$myString =~ s/&apos;/'/g;	# replace any &apos; with '
	$myString =~ s/&quot;/"/g;	# replace any &quot; with "
	return( $myString );
}
