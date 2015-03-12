# Download #

Download the latest version from https://mythweather-accuweather.googlecode.com/svn/trunk/accuweather.pl

e.g. from linux command type

```
wget https://mythweather-accuweather.googlecode.com/svn/trunk/accuweather.pl

```


# Installation #
To install this script

```
sudo mkdir /usr/share/mythtv/mythweather/scripts/accuweather
sudo cp ~/accuweather*.pl /usr/share/mythtv/mythweather/scripts/accuweather/
sudo chmod -v 0755 /usr/share/mythtv/mythweather/scripts/*/*.pl
```
See also the regular mythtv wiki page http://www.mythtv.org/wiki/MythWeather

# Set Language #

To set the language, open the script and edit line 34:

`my $mylanguage = 0;   #(GB=0,FR=1,NL=2) `

Change the 0 in 1 for French, 2 for Dutch.
Let me know if you have other translations, I can add them.
