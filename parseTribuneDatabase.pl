#!/usr/bin/perl

#
# parseTribuneDatabase.pl
#
# parse Tribune database XML into tab-delimited text file
#
# version 0.1
# created 2013-01-03
# modified 2013-01-04
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
my ( $movie_info );
my ( $releases, $release, $release_type, $release_date, $release_attributes );
my ( $original_release_year, $original_release_date );
my ( $distributors, $distributor, $distributor_name, $distribution_country );
my ( $sound_mixes, $sound_mix );
my ( $picture_formats, $picture_format );
my ( $production_companies, $production_company_name );
my ( $trailers, $trailer, $trailer_format, $trailer_url );
my ( $sound_mixes, $sound_mix, $sound_mix_text, $sound_mix_list );
my ( $picture_formats, $picture_format, $picture_format_list );
my ( $production_compaies, $production_company_name, $production_company_list );
my ( $definitve_original_release_date, $definitive_distributor_name, $definitive_distribution_country );
my ( $official_url, $trailers, $trailer, $trailer_format, $trailer_url );
my ( $images, $image, $image_attributes, $image_type, $image_width, $iamge_height );
my ( $image_primary, $image_category, $image_uri, $image_caption );
my ( $animation, $original_audio_language );

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
					"color code\t" .
					"release year\t" .
					"original release date\t" .
					"original distributor\t" .
					"original release country\t" .
					"sound mixes\t" .
					"picture formats\t" .
					"production companies\t" .
					"official url\t" .
					"trailer\t" .
					"poster art\t" .
					"animation\t" .
					"original audio language\n";

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
	if ( $program =~ m/<movieInfo>(.*?)<\/movieInfo>/ms ) {
		$movie_info = trim( $1 );
		
		# there are multiple subtags here
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
		#	officialURL
		# 	trailers
		#		trailer
		#			format
		#			url
		
		# releases
		$original_release_year = "";
		$original_release_date = "";
		$distributor_name = "";
		$distribution_country = "";
		$definitve_original_release_date = "";
		$definitive_distributor_name = "";
		$definitive_distribution_country = "";
		if ( $movie_info =~ m/<releases>(.*?)<\/releases>/ms ) {
			$releases = trim( $1 );

			# release year is different from the rest :(
			if ( $releases =~ m/<release type="Year" date="(.*?)"\/>/ms ) {
				$original_release_year = trim( $1 );
			}

			## when we have both a release year and original release tag,
			## we have to do this a little differently to avoid finding the closed tag
			while ( $releases =~ m/<release ([^\/]*?)>(.*?)<\/release>/gms ) {
				$release_attributes = trim( $1 );
				$release = trim( $2 );
				if ( $release_attributes =~ m/type="Original"/ ) {
					## unfortunately, doing things this way has the downside of finding the last
					## original release tag - and runs the risk of mixing up data between them.
					## so we need to clear out the output variable for each find to only give us
					## the last original release tag
					##
					## should we check the country against $country_list?
					## make a separate $definitve_original_release_date, $definitive_distributor_name, $definitive_distribution_company
					## and if ( $distribution_country eq $country_list )
					## 		set these values
					$original_release_date = "";
					$distributor_name = "";
					$distribution_country = "";
					if ( $release_attributes =~ m/date="(.*?)"/ ) {
						$original_release_date = trim( $1 );
					}
					if ( $release =~ m/<distributors>(.*?)<\/distributors>/ms ) {
						$distributor = trim( $1 );
						if ( $distributor =~ m/<name>(.*?)<\/name>/ms ) {
							$distributor_name = unescape( trim( $1 ) ) ;
						}
					}
					if ( $release =~ m/<country>(.*?)<\/country>/ms ) {
						$distribution_country = unescape( trim( $1 ) );
					}
					## check this release's country against $country_list
					## if they match, we should use this one for sure
					if ( $distributor_name eq $country_list ) {
						$definitve_original_release_date = $original_release_date;
						$definitive_distributor_name = $distributor_name;
						$definitive_distribution_country = $distribution_country;
					}
				}
			}
			
			## now check to see if we came up with a definitive original distribution
			## if we have, use that instead of whatever else we landed on
			if ( $definitve_original_release_date ne "" ) {
				$original_release_date = "$definitve_original_release_date";
				$distributor_name = "$definitive_distributor_name";
				$distribution_country = "$definitive_distribution_country";
			}
			
			###
			###	OK, so this still isn't perfect
			###
			###	turns out, if there was a staged release in the original country,
			###	it isn't listed as "Original"
			### but it lists "Limted" or "Expanded" or "Wide"
			### should we look for earliest date with the original country or release?
			###
			###	think about this and come back to it
			###
			
		}

		# soundMixes
		$sound_mix_list = "";
		if ( $movie_info =~ m/<soundMixes>(.*?)<\/soundMixes>/ms ) {
			$sound_mixes = trim( $1 );
			while( $sound_mixes =~ m/<soundMix>(.*?)<\/soundMix>/gms ) {
				$sound_mix = unescape( trim( $1 ) );
				if ( $sound_mix_list ne "" ) { $sound_mix_list .= ", "; }
				$sound_mix_list .= $sound_mix;
			}
		}
		
		# pictureFormats
		$picture_format_list = "";
		if ( $movie_info =~ m/<pictureFormats>(.*?)<\/pictureFormats>/ms ) {
			$picture_formats = trim( $1 );
			while( $picture_formats =~ m/<pictureFormat>(.*?)<\/pictureFormat>/gms ) {
				$picture_format = unescape( trim( $1 ) );
				if ( $picture_format_list ne "" ) { $picture_format_list .= ", "; }
				$picture_format_list .= $picture_format;
			}
		}
		
		# productionCompanies
		$production_company_list = "";
		if ( $movie_info =~ m/<productionCompanies>(.*?)<\/productionCompanies>/ms ) {
			$production_companies = trim( $1 );
			while( $production_companies =~ m/<name>(.*?)<\/name>/gms ) {
				$production_company_name = unescape( trim( $1 ) );
				if ( $production_company_list ne "" ) { $production_company_list .= ", "; }
				$production_company_list .= $production_company_name;
			}
		}
		
		# officialURL
		if ( $movie_info =~ m/<officialURL>(.*?)<\/officialURL>/ms ) {
			$official_url = trim( $1 );
		} else {
			$official_url = "";
		}
		
		# trailers
		$trailer_url = "";
		if ( $movie_info =~ m/<trailers>(.*?)<\/trailers>/ms ) {
			$trailers = trim( $1 );
			## there could be more than one trailer listed, but I haven't seen it yet
			## let's do the same as above - use the last one listed if there are more than one
			if ( $trailers =~ m/<URL>(.*?)<\/URL>/ms ) {
				$trailer_url = trim( $1 );
			}
		}
	}
	
	# get images tag
	### what we really want here is the biggest Poster Art image URL
	### however, these are partial URLs, so I don't know how much help this is, really
	### stub it out for now
	$image_uri = "";
	
#	my ( $images, $image, $image_attributes, $image_type, $image_width, $iamge_height );
#	my ( $image_primary, $image_category, $image_uri, $image_caption );
	
	# get animation tag
	if ( $program =~ m/<animation>(.*?)<\/animation>/ms ) { $animation = trim( $1 ); }
		else { $animation = ""; }
	
	# get origAudioLang tag
	if ( $program =~ m/<origAudioLang>(.*?)<\/origAudioLang>/ms ) { $original_audio_language = trim( $1 ); }
		else { $original_audio_language = ""; }
	
	
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
						"$color_code\t" .
						"$original_release_year\t" .
						"$original_release_date\t" .
						"$distributor_name\t" .
						"$distribution_country\t" .
						"$sound_mix_list\t" .
						"$picture_format_list\t" .
						"$production_company_list\t" .
						"$official_url\t" .
						"$trailer_url\t" .
						"$image_uri\t" .
						"$animation\t" .
						"$original_audio_language\n";
			
}



close( OUTPUT_FILE );

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
