#! /usr/bin/perl -w

#
# Parts based on nwsxml.pl by Lucien Dunning
# TODO: Conversion of units. Currently the units are ignored

use strict;
use XML::Simple;
#use LWP::Simple;
use LWP::UserAgent;
# Ideally we would use the If-Modified-Since header
# to reduce server load, but they ignore it
#use HTTP::Cache::Transparent;
use Getopt::Std;
use File::Basename;
use lib dirname($0);
#use Data::Dumper;


our ($opt_v, $opt_t, $opt_T, $opt_l, $opt_u, $opt_d);

my (%mythoutput,$value,$keyword);

my $name = 'Accu.com-Current,3D,6D';
my $version = 0.1;
my $author = 'Marcel Verpaalen';
my $email = 'marcel.verpaalen@gmail.com';
my $updateTimeout = 120*60;
my $retrieveTimeout = 30;
my @types = ('cclocation', 'station_id', 'copyright',
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

getopts('Tvtlu:d:');

if (defined $opt_v) {
    print "$name,$version,$author,$email\n";
    exit 0;
}

if (defined $opt_T) {
    print "$updateTimeout,$retrieveTimeout\n";
    exit 0;
}

if (defined $opt_l) {
 my $search = shift;
    #my $location_base_url = 'file:////usr/share/mythtv/mythweather/scripts/accu.com/';
	my $location_base_url = 'http://forecastfox.accuweather.com/adcbin/forecastfox/locate_city.asp?location=';
my $response = get $location_base_url .$search ;
die unless defined $response;
#add encoding as it does not appear in the original XML and perl seems not to like that
my $sr='xml version="1.0"';
my $repl='xml version="1.0" encoding="iso-8859-1"';
$response =~ s/$sr/$repl/ ;
my $xml = XMLin($response);

if (!$xml) {
    die "Not xml";
}

foreach my $item (@{$xml->{citylist}->{location}}){
printf "%s::%s", $item->{location},  $item->{city} . ", " .  $item->{state} . "\n" ; 
}
 exit 0;

}

if (defined $opt_t) {
    foreach (@types) {print; print "\n";}
    exit 0;
}

if (defined $opt_d) {
    $dir = $opt_d;
}

# we get here, we're doing an actual retrieval, everything must be defined
my $locid = shift;
if (!(defined $opt_u && defined $locid && !$locid eq "")) {
    die "Invalid usage";
}

my $units = $opt_u;

my $type;
foreach $type (@types){$mythoutput{$type}='N/A' ;};


#my $base_url = 'http://wwwa.accuweather.com/world-index-forecast.asp?partner=forecastfox&locCode=';
my $base_url = 'http://forecastfox.accuweather.com/adcbin/forecastfox/weather_data.asp?metric=1&partner=forecastfox&location=';
#my $base_url = 'file:////usr/share/mythtv/mythweather/scripts/accu.com/sample.xml';
#my $response = get $base_url ;

 my $ua = LWP::UserAgent->new;
 $ua->timeout(20);
 $ua->env_proxy;
 $ua->agent('Mozilla/5.0');

 my $response = $ua->get($base_url . $locid);
 
 if ($response->is_success) {
    # print $response->decoded_content;  # or whatever
 }
 else {
     die $response->status_line;
 }
 
#my $response = get $base_url . $locid;
#die unless defined $response;

my $xml = XMLin($response->decoded_content );

if (!$xml) {
    die "Not xml";
}

# Conversion of keys accu->Myth
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

#header data
$mythoutput{"copyright"} = $xml->{copyright};
$mythoutput{"station_id"} = $locid ;
$mythoutput{"cclocation"} = $xml->{local}->{city} . ", " . $xml->{local}->{state} ;
$mythoutput{"3dlocation"} = $xml->{local}->{city} . ", " . $xml->{local}->{state} ;
$mythoutput{"6dlocation"} = $xml->{local}->{city} . ", " . $xml->{local}->{state} ;
$mythoutput{"observation_time"} = "Updated: " . $xml->{forecast}->{day}->[0]->{obsdate} . " " . $xml->{local}->{time} ;
$mythoutput{"updatetime"} = "Updated: " . $xml->{forecast}->{day}->[0]->{obsdate} . " " . $xml->{local}->{time} ;
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

#conversions / mapping
if ( exists $icons { $mythoutput {"weather_icon"}}) {
	$mythoutput {"weather_icon"} = $icons {$mythoutput {"weather_icon"}}; }
else { $mythoutput {"weather_icon"} = "unknown.png" ; }
$mythoutput {"relative_humidity"} =~ s/%// ;
$mythoutput {"wind_spdgst"} .= " (" . $mythoutput {"wind_gust"} . ")" ;

#3D forcast
#my $forecast = $xml->{forecast};
#print Dumper ($forecast);
#
#foreach my $forecast (keys (%{$xml->{forecast}})) {
#print Dumper ($forecast);
#}

my $i;
for ($i = 0; $i < 6; ++$i) {

$mythoutput{"date-" . $i} = $xml->{forecast}->{day}->[$i]->{obsdate} ;
$mythoutput{"icon-" . $i} = $xml->{forecast}->{day}->[$i]->{daytime}->{weathericon} ;
$mythoutput{"low-" . $i} = $xml->{forecast}->{day}->[$i]->{daytime}->{lowtemperature} ;
$mythoutput{"high-" . $i} = $xml->{forecast}->{day}->[$i]->{daytime}->{hightemperature} ;
if ( exists $icons { $mythoutput {"icon-" . $i}}) {
	$mythoutput {"icon-" . $i} = $icons {$mythoutput {"icon-" . $i}}; }
else { $mythoutput {"icon-" . $i} = "unknown.png" ; }
}


#output the data
#while (($keyword, $value) = each(%mythoutput))
foreach $keyword (@types)
{ $value = $mythoutput{$keyword}; 
	if (ref($value) eq 'HASH'){
		printf "%s::%s\n",$keyword,$value->{content};
	}
	else {
	printf "%s::%s\n",$keyword,$value;
	}
}
