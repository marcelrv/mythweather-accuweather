#! /usr/bin/perl -w
#This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author Marcel Verpaalen#
# Parts based on nwsxml.pl by Lucien Dunning
#includes several updates/patches/fixes from   gilles74 - mythtv-fr, brandyndave, marius.hennecke,
#
use strict;
use XML::Simple;
use LWP::Simple;
use LWP::UserAgent;
# Ideally we would use the If-Modified-Since header
# to reduce server load, but they ignore it
#use HTTP::Cache::Transparent;
use Getopt::Std;
use File::Basename;
use lib dirname($0);

#Put here your language key
my $mylanguage = 0;   #(GB=0,FR=1,NL=2,DE=3)

#and here translations (key,[GB,FR,NL,]
my %translationtable  = (
	"observation_time",["Observation of","Observations du","Observatie van","Beobachtung von"],
	"updatetime",["Updated","Previsions du","Vernieuwd","Aktualisiert"],
	"unknown",["Unknown","Inconnu","Onbekend","Unbekannt"]);

our ($opt_v, $opt_t, $opt_T, $opt_l, $opt_u, $opt_d);

my (%mythoutput,$value,$keyword);

my $name = 'Accu.com-Current-3D-6D';
my $version = 0.4;
my $author = 'Marcel Verpaalen';
my $email = 'marcel.verpaalen@gmail.com';

# Basic options
     my $updateTimeout = 120*60;
     my $retrieveTimeout = 30;
     my @types = ('cclocation', 'station_id', 'copyright', 'daycode',
        	'observation_time', 'weather', 'temp', 'relative_humidity',
        	'wind_dir', 'pressure', 'visibility', 'weather_icon',
        	'appt', 'wind_spdgst', 
	'3dlocation', 
        	'date-0', 'icon-0', 'low-0', 'high-0',
        	'date-1', 'icon-1', 'low-1', 'high-1', 
        	'date-2', 'icon-2', 'low-2', 'high-2', 'updatetime',
	'6dlocation', 
		'date-3', 'icon-3', 'low-3', 'high-3',
        	'date-4', 'icon-4', 'low-4', 'high-4',
        	'date-5', 'icon-5', 'low-5', 'high-5', 
		);

      my $dir = "./";


# definition of options
getopts('Tvtlu:d:');

       # option v  -  script informations
          if (defined $opt_v) {
              print "$name,$version,$author,$email\n";
          exit 0;
          }
       # option T  -  delay values
          if (defined $opt_T) {
              print "$updateTimeout,$retrieveTimeout\n";
          exit 0;
          }
       # option l -search location
          if (defined $opt_l) {
              my $search = shift;
              my $location_base_url = 'http://forecastfox.accuweather.com/adcbin/forecastfox/locate_city.asp?location=';

              my $ua = LWP::UserAgent->new;
                 $ua->timeout(20);
                 $ua->env_proxy;
                 $ua->agent('Mozilla/5.0');

              my $response = $ua->get($location_base_url . $search);
                 die unless defined $response;
              my $xml = XMLin($response->decoded_content, forcearray => ['location']);

              if (!$xml) {
                   die "Not xml";
              }

              foreach my $item (@{$xml->{citylist}->{location}}){
              # we arbitrarily replace all '|' chars with '~' to sidestep argument passing problems
                 $item->{location} =~ s/\|/\~/g;
                 printf "%s::%s", $item->{location},  $item->{city} . ", " .  $item->{state} . "\n" ; 
              }
              exit 0;
          }


      # Option t  - give used items 
         if (defined $opt_t) {
             foreach (@types) {print; print "\n";}
             exit 0;
         }

     # Option d  - defined the directory for the cache
        if (defined $opt_d) {
             $dir = $opt_d;
        }

	 # Option u - units of measure to return, metric (1) or imperial (0)
	    my $units;
		if ( defined $opt_u ) {
			if ( $opt_u eq "ENG" ) {
				$units = 0;
			}
			else {
				$units = 1;
			}
		}

# main program - download data

my $locid = shift;

# we have to restore all '~' chars to the original '|' before assembling the URL
$locid =~ s/\~/\|/g;

# we get here, we're doing an actual retrieval, everything must be defined
	if (!(defined $units && defined $locid && !$locid eq "")) {
	    die "Invalid usage";
	}

	my $type;
foreach $type (@types){$mythoutput{$type}='N/A' ;};

	my $url = "http://forecastfox.accuweather.com/adcbin/forecastfox/weather_data.asp?metric=" . $units . "&partner=forecastfox&location=";
	my $base_url = "$url$locid" ;
#my $base_url = 'file:////usr/share/mythtv/mythweather/scripts/accu.com/sample.xml';


	 my $ua = LWP::UserAgent->new;
	 $ua->timeout(20);
 	$ua->env_proxy;
 	$ua->agent('Mozilla/5.0');


 	my $response = $ua->get($base_url);
 
 	if ($response->is_success) {

	 }
	 else {
 	    die $response->status_line;
	 }
 

	my $xml = XMLin($response->decoded_content );

	if (!$xml) {
	    die "Not xml";
	}

      # Conversion of keys accuweather->Myth
           my %conv  = ("temperature","temp",
			"weathertext","weather",
			"winddirection","wind_dir",
			"windgusts","wind_gust",
			"humidity", "relative_humidity",
			"visibility","visibility",
			"pressure","pressure",
			"realfeel","appt",
			"weathericon","weather_icon",
			"windspeed","wind_spdgst");


      # header data
           $mythoutput{"copyright"} = $xml->{copyright};
           $mythoutput{"station_id"} = $locid ;
           $mythoutput{"cclocation"} = $xml->{local}->{city} . ", " . $xml->{local}->{state} ;
           $mythoutput{"3dlocation"} = $xml->{local}->{city} . ", " . $xml->{local}->{state} ;
           $mythoutput{"6dlocation"} = $xml->{local}->{city} . ", " . $xml->{local}->{state} ;
           $mythoutput{"observation_time"} = $translationtable{"observation_time"}[$mylanguage] . " : " . $xml->{forecast}->{day}->[0]->{obsdate} . " " . $xml->{local}->{time} ;
           $mythoutput{"updatetime"} = $translationtable{"updatetime"}[$mylanguage] . " : " . $xml->{forecast}->{day}->[0]->{obsdate} . " " . $xml->{local}->{time} ;


     # Current conditions
	foreach my $key (keys (%{$xml->{currentconditions}})){

	   if ( exists $conv {$key}  ) {
	        $value = $xml->{currentconditions}->{$key};
	   if (ref($value) eq 'HASH'){
		$mythoutput{$conv {$key}} = $value->{content} ;}
	   else {
		$mythoutput{$conv {$key}} = $value ;
		}
	        #printf $conv {$key}  . "::%s" . "\n" , $xml->{currentconditions}->{$key} ;
	   }  
	   else {
		# printf "Not processed: " . $key . "=%s" . "\n" ,  $xml->{currentconditions}->{$key} ;
	        }
           }

    #Wind Dir translation
        my %wind_dirs = ("N",["North","Nord","Noord","Nord"],
					"NNE",["NorthNorthEast","Nord-nord-est","Noordnoordoost","Dienstag"],
					"NE", ["NorthEast","Nord-est","Noordoost","Nordost"],
					"ENE",["EastNorthEast","Est-nord-est","Oostnoordoost","Ost-Nordost"],
					"E",["East","Est","Oost","Ost"],
					"ESE",["EastSouthEast","Est-sud-est","Oostzuidoost","Ost-Sudost"],
					"SE",["SouthEast","Sud-est","Zuidoost","Südost"],
					"SSE",["SouthSouthEast","Sud-sud-est","Zuidzuidoost","Süd-Südost"],
					"S",["South","Sud","Zuid","Süd"],
					"SSW",["SouthSouthwest","Sud-sud-ouest","Zuidzuidwest","Süd-Südwest"],
					"SW",["Southwest","Sud-ouest","Zuidwest","Südwest"],
					"WSW",["WestSouthwest","Ouest-sud-ouest","Westzuidwest","West-Südwest"],
					"W",["West","Ouest","West","West"],
					"WNW",["WestNorthwest","Ouest-nord-ouest","Westnoordwest","West-Nordwest"],
					"NW",["Northwest","Nord-ouest","Noordwest","Nordwest"],
					"NNW",["NorthNorthwest","Nord-nord-ouest","Noordnoordwest","Nord-Nordwest"]);

    # conversions / translation Wind dirs
        if ( exists $wind_dirs { $mythoutput {"wind_dir"}}[$mylanguage]) {
	      $mythoutput {"wind_dir"} = $wind_dirs {$mythoutput {"wind_dir"}}[$mylanguage]; };

		  # day mappings to be made
        my %daycodes = ("Monday",["Monday","Lundi","Maandag","Montag"],
	                "Tuesday",["Tuesday","Mardi","Dinsdag","Dienstag"],
	                "Wednesday",["Wednesday","Mercredi","Woensdag","Mittwoch"],
	                "Thursday",["Thursday","Jeudi","donderdag","Donnerstag"],
	                "Friday",["Friday","Vendredi","Vrijdag","Freitag"],
	                "Saturday",["Saturday","Samedi","Zaterdag","Samstag"],
	                "Sunday",["Sunday","Dimanche","Zondag","Sonntag"]);

    # conversions days/ mapping
        if ( exists $daycodes { $mythoutput {"daycode"}}[$mylanguage]) {
	      $mythoutput {"daycode"} = $daycodes {$mythoutput {"daycode"}}[$mylanguage]; };

	# weather text mappings
	my %weathercodes = (
		"Sunny",["Sunny","Sunny","Sunny","Sonnig"],
		"Mostly Sunny",["Mostly Sunny","Mostly Sunny","Mostly Sunny","Meist Sonnig"],
		"Partly Sunny",["Partly Sunny","Partly Sunny","Partly Sunny","Teilweise Sonnig"],
		"Intermittent Clouds",["Intermittent Clouds","Intermittent Clouds","Intermittent Clouds","Zwischenzeitlich bewölkt"],
		"Hazy Sunshine",["Hazy Sunshine","Hazy Sunshine","Hazy Sunshine","Diesig"],
		"Mostly Cloudy",["Mostly Cloudy","Mostly Cloudy","Mostly Cloudy","Meist bewölkt"],
		"Cloudy (AM and PM)",["Cloudy (AM and PM)","Cloudy (AM and PM)","Cloudy (AM and PM)","Bewölkt"],
		"Dreary (AM and PM)",["Dreary (AM and PM)","Dreary (AM and PM)","Dreary (AM and PM)","Trüb"],
		"Fog (AM and PM)",["Fog (AM and PM)","Fog (AM and PM)","Fog (AM and PM)","Nebelig"],
		"Showers (AM and PM)",["Showers (AM and PM)","Showers (AM and PM)","Showers (AM and PM)","Schauer"],
		"Mostly Cloudy with Showers",["Mostly Cloudy with Showers","Mostly Cloudy with Showers","Mostly Cloudy with Showers","Meist bewölkt mit Schauern"],
		"Partly Sunny with Showers",["Partly Sunny with Showers","Partly Sunny with Showers","Partly Sunny with Showers","Teilweise sonnig mit Schauern"],
		"Thunderstorms (AM and PM)",["Thunderstorms (AM and PM)","Thunderstorms (AM and PM)","Thunderstorms (AM and PM)","Gewitter"],
		"Mostly Cloudy with Thunder Showers",["Mostly Cloudy with Thunder Showers","Mostly Cloudy with Thunder Showers","Meist bewölkt mit Gewitterschauern","Mostly Cloudy with Thunder Showers"],
		"Partly Sunny with Thunder Showers",["Partly Sunny with Thunder Showers","Partly Sunny with Thunder Showers","Partly Sunny with Thunder Showers","Teilweise Sonnig mit Gewitterschauern"],
		"Rain (AM and PM)",["Rain (AM and PM)","Rain (AM and PM)","Rain (AM and PM)","Regen"],
		"Flurries (AM and PM)",["Flurries (AM and PM)","Flurries (AM and PM)","Flurries (AM and PM)","Schneetreiben"],
		"Mostly Cloudy with Flurries",["Mostly Cloudy with Flurries","Mostly Cloudy with Flurries","Mostly Cloudy with Flurries","Meist bewölkt mit Schneetreiben"],
		"Partly Sunny with Flurries",["Partly Sunny with Flurries","Partly Sunny with Flurries","Partly Sunny with Flurries","Teilweise sonnig mit Schneetreiben"],
		"Snow (AM and PM)",["Snow (AM and PM)","Snow (AM and PM)","Snow (AM and PM)","Schnee"],
		"Mostly Cloudy with Snow",["Mostly Cloudy with Snow","Mostly Cloudy with Snow","Mostly Cloudy with Snow","Meist bewölkt mit Schnee"],
		"Ice (AM and PM)",["Ice (AM and PM)","Ice (AM and PM)","Ice (AM and PM)","Eis"],
		"Sleet (AM and PM)",["Sleet (AM and PM)","Sleet (AM and PM)","Sleet (AM and PM)","Schneeregen"],
		"Freezing Rain (AM and PM)",["Freezing Rain (AM and PM)","Freezing Rain (AM and PM)","Freezing Rain (AM and PM)","Eisregen"],
		"Rain and Snow Mixed (AM and PM)",["Rain and Snow Mixed (AM and PM)","Rain and Snow Mixed (AM and PM)","Rain and Snow Mixed (AM and PM)","Schneeregen"],
		"Hot (AM and PM)",["Hot (AM and PM)","Hot (AM and PM)","Hot (AM and PM)","Heiß"],
		"Cold (AM and PM)",["Cold (AM and PM)","Cold (AM and PM)","Cold (AM and PM)","Kalt"],
		"Windy (AM and PM)",["Windy (AM and PM)","Windy (AM and PM)","Windy (AM and PM)","Windig"],
		"Clear",["Clear","Clear","Clear","Klar"],
		"Mostly Clear",["Mostly Clear","Mostly Clear","Mostly Clear","Meist klar"],
		"Partly Cloudy",["Partly Cloudy","Partly Cloudy","Partly Cloudy","Teilweise bewölkt"],
		"Intermittent Clouds",["Intermittent Clouds","Intermittent Clouds","Intermittent Clouds","Zwischenzeitlich bewölkt"],
		"Hazy",["Hazy","Hazy","Hazy","Diesig"],
		"Partly Cloudy with Showers",["Partly Cloudy with Showers","Partly Cloudy with Showers","Partly Cloudy with Showers","Teilweise bewölkt mit Schauern"],
		"Partly Cloudy with Thunder Showers",["Partly Cloudy with Thunder Showers","Partly Cloudy with Thunder Showers","Partly Cloudy with Thunder Showers","PTeilweise bewölkt mit Gewitterschauern"]
	);

	# conversion weather text
	if ( exists $weathercodes { $mythoutput {"weather"}}[$mylanguage]) {
		$mythoutput {"weather"} = $weathercodes {$mythoutput {"weather"}}[$mylanguage]; };

    #icon mappings to be made
             my %icons = ("01","sunny.png",
			  "02","sunny.png",
	   		  "03","sunny.png",
	 		  "04","pcloudy.png",
	 		  "05","pcloudy.png",
			  "06","mcloudy.png",
			  "07","pcloudy.png",
			  "08","cloudy.png",
			  "11","fog.png",
			  "12","lshowers.png",
			  "13","lshowers.png",
			  "14","showers.png",
			  "15","thunshowers.png",
			  "16","thunshowers.png",
			  "17","thunshowers.png",
			  "18","showers.png",
			  "19","snowshow.png",
			  "20","snowshow.png",
			  "21","sunny.png",
			  "22","snowshow.png",
			  "23","snowshow.png",
			  "24","snowshow.png",
			  "25","lshowers.png",
			  "26","lshowers.png",
			  "27","unknown.png",
			  "28","unknown.png",
			  "29","rainsnow.png",
			  "30","sunny.png",
			  "31","snowshow.png",
			  "32","unknown.png",
			  "33","fair.png",
			  "34","fair.png",
			  "35","fair.png",
			  "36","fair.png",
			  "37","fair.png",
			  "38","fair.png",
			  "39","lshowers.png",
			  "40","lshowers.png",
			  "41","thunshowers.png",
			  "43","lshowers.png",
			  "44","flurries.png",
			  "45","flurries.png",
			  "45","unknown.png",
			  "46","fair.png");

	# conversions icon/ mapping
		if ( exists $icons { $mythoutput {"weather_icon"}}) {
			$mythoutput {"weather_icon"} = $icons {$mythoutput {"weather_icon"}}; }
		else { $mythoutput {"weather_icon"} = "unknown.png" ; }
			$mythoutput {"relative_humidity"} =~ s/%// ;

	# conversions m/s en km/h for the windspeed
		$mythoutput {"windgust"} = $mythoutput {"wind_gust"}*3.60 ;
		$mythoutput {"windspdgst"} = $mythoutput {"wind_spdgst"}*3.60 ;
		$mythoutput {"wind_gust"} = $mythoutput {"windgust"} ;
		$mythoutput {"wind_spdgst"} = $mythoutput {"windspdgst"} ;
		$mythoutput {"wind_spdgst"} .= " (" . $mythoutput {"wind_gust"} . ")" ;


	# download forecast 3/6 days
		my $i;
		for ($i = 0; $i < 6; ++$i) {

			$mythoutput{"date-" . $i} = $xml->{forecast}->{day}->[$i]->{daycode} ;
			$mythoutput{"icon-" . $i} = $xml->{forecast}->{day}->[$i]->{daytime}->{weathericon} ;
			$mythoutput{"low-" . $i} = $xml->{forecast}->{day}->[$i]->{daytime}->{lowtemperature} ;
			$mythoutput{"high-" . $i} = $xml->{forecast}->{day}->[$i]->{daytime}->{hightemperature} ;

			if ( exists $daycodes { $mythoutput {"date-" . $i}}[$mylanguage]) {
				$mythoutput {"date-" . $i} = $daycodes {$mythoutput {"date-" . $i}}[$mylanguage]; }


			if ( exists $icons { $mythoutput {"icon-" . $i}}) {
				$mythoutput {"icon-" . $i} = $icons {$mythoutput {"icon-" . $i}}; }
			else { $mythoutput {"icon-" . $i} = "unknown.png" ; }
		}


	#output the data

		foreach $keyword (@types)
		{ $value = $mythoutput{$keyword}; 
		if (ref($value) eq 'HASH'){
			printf "%s::%s\n",$keyword,$value->{content};
		}
		else {
		printf "%s::%s\n",$keyword,$value;
		}
}
