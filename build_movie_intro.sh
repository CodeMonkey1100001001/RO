#!/bin/sh
#example:
#./build_movie_intro.sh "https://en.wikipedia.org/wiki/Jamaica_Inn_(film)"

DATADIR="./movie_data"

#First create a place to store the raw data
mkdir -p $DATADIR

#Grab the wikipedia entry
lynx -source "$1" >$DATADIR/wiki.source


MOVIETITLE=`echo $1 |  cut -d "/" -f 5 | tr -c '[[:alnum:]].-' ' '`


echo Title of the film: $MOVIETITLE


MOVIEDIRECTOR=`cat $DATADIR/wiki.source | hxselect -c -s "\n" -c -i "tr" | grep Directed -A1 | hxpipe | grep "(a" -A1 | grep "-" | tr -d '-'`

echo Directed by $MOVIEDIRECTOR

MOVIESTAR=`cat $DATADIR/wiki.source | hxselect -c -s "\n" -c -i "tr" | grep Starring -A1 | hxpipe | grep "(a" -A1 | grep "-" | tr -d '-'`

echo Starring $MOVIESTAR


MOVIERELEASE=`cat $DATADIR/wiki.source | hxselect -c -s "\n" -c -i "tr" | grep Release -A2| hxpipe | grep "(td" -A2 | tr ' ' '\n' | grep 1...`

echo Release Date $MOVIERELEASE


echo "Synopsis:"

echo "Hello I'm raspi. Welcom to the Timeless Classics Movies Channel." >$DATADIR/synopsis.txt

cat $DATADIR/wiki.source | hxremove sup | hxselect -s "\n" -c -i "p" | awk '{gsub("<[^>]*>", "")}1'  | awk 'NR<4' >>$DATADIR/synopsis.txt

echo ",,,  Here is the $MOVIERELEASE classic $MOVIETITLE" >>$DATADIR/synopsis.txt

cat $DATADIR/synopsis.txt

echo "Rending synopsis.txt to wav file...this make take a while"

text2wave $DATADIR/synopsis.txt -o $DATADIR/synopsis.wav


#get it ready for speech synthesis
#tr -c '[[:alnum:]].\n' ' '



#Now get some images about it
mkdir -p $DATADIR/IMAGES
cd $DATADIR/IMAGES 

SEARCHSTR="$MOVIETITLE $MOVIERELEASE"
echo Search[$SEARCHSTR]
echo ../../googliser.sh -n 8 -g -p \'$SEARCHSTR\' | sh
sleep 16


SEARCHSTR="$MOVIETITLE $MOVIEDIRECTOR $MOVIERELEASE"
echo Search[$SEARCHSTR]
echo ../../googliser.sh -n 8 -g -p \'$SEARCHSTR\' | sh
sleep 18

SEARCHSTR="$MOVIEDIRECTOR $MOVIERELEASE"
echo Search[$SEARCHSTR]
echo ../../googliser.sh -n 8 -g -p \'$SEARCHSTR\' | sh
sleep 24

SEARCHSTR="$MOVIESTAR $MOVIERELEASE"
echo Search[$SEARCHSTR]
echo ../../googliser.sh -n 8 -g -p \'$SEARCHSTR\' | sh
cd ../..

mkdir -p $DATADIR/RNDIMG

find  $DATADIR/IMAGES/ -type f | awk '1==1 {printf("cp \"%s\" ./movie_data/RNDIMG/%s.jpg\n",$0,a+1);a=a+1;}' | sh

SYNOPSYSLEN=`soxi -D movie_data/synopsis.wav`

SYNOPSYSLEN=`echo $SYNOPSYSLEN | awk '{print int($0*30)}0'`

echo "Making the Movie Intro"

/home/pi/RO/melt $DATADIR/RNDIMG/.all.jpg in=0 out=$SYNOPSYSLEN ttl=75 -attach crop center=1 -attach affine transition.cycle=225 transition.geometry="0=0/0:100%x100%;74=-100/-100:120%x120%;75=-60/-60:110%x110%;149=0/0:110%x110%;150=0/-60:110%x110%;224=-60/0:110%x110%" -filter luma cycle=75 duration=25 -track $DATADIR/synopsis.wav -transition mix -consumer avformat:$DATADIR/movie_intro.mp4 vcodec=libx264 acodec=aac 

echo "Movie Complete"

