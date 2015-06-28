#!/usr/bin/perl
################################################
 #    #   ####   #    #     #    #####   ######
  #  #   #       #    #     #    #    #  #
   ##     ####   #    #     #    #    #  #####
   ##         #  # ## #     #    #####   #
  #  #   #    #  ##  ##     #    #       #
 #    #   ####   #    #     #    #       ######
################################################
use strict;
use Time::HiRes();
use X11::GUITest qw( :ALL );
use FindBin;

use JSON::Parse 'json_file_to_perl';
#debug
#use Smart::Comments;


my $confSplitter = "/";

my $forceThreshold = 70;


#window for handling distinct events
my $eventTimeWindow = 0.200;

#list of arguments
my $distanceArgument               = "-d";
my $pollingTimeArgument            = "-m";
my $verboseArgument                = "-v";
my $verboseLevelTwoArgument        = "-vv";
my $verboseLevelThreeArgument      = "-vvv";
my $disableWhileTypingArgument     = "--disable-while-typing";
my $disableTimeAfterTypingArgument = "--disable-time";




my $longPressCode = "longPress";
my $swipeCode = "swipe";
my $edgeSwipeCode = "edgeSwipe";



#default basic distance
my $baseDist = 0.3;

#polling interval in milliseconds
my $pollingInterval = 20;

#default configuration file name
my $confFileName = "default.json";

#vervose with verbose level
my $verbose = 0;

#disable while typing
my $disableWhileTyping = "";
my $setDisableWhileTyping = "-K -t";

my $disableAfterTypingTime = "-i ". 0.5;
my $setDisableAfterTypingTime = "-i";

#scroll delta
my $vertScrollDelta  = 0;
my $horizScrollDelta = 0;

#touchpad edges
my $leftEdge         = 0;
my $rightEdge        = 0;
my $topEdge          = 0;
my $bottomEdge       = 0;

#depth is hardcoded. didn't know how to get it
my $touchpadHeight   = 0;
my $touchpadWidth    = 0;
my $touchpadDepth    = 500;

#minimum threshold for z is hardcoded because depth is too
my $xMinThreshold    = 0;
my $yMinThreshold    = 0;
my $zMinThreshold    = 20;

my $innerEdgeLeft    = 0;
my $innerEdgeRight   = 0;
my $innerEdgeTop     = 0;
my $innerEdgeBottom  = 0;

#touchpad axys
my $xAxis = "x";
my $yAxis = "y";
my $zAxis = "z";

#movement orientation
my $positiveMovement = "+";
my $negativeMovement = "-";


#touchpad states
my $touchpadDefaultState = "0";
my $touchpadNotEdgeState = "1";
my $touchpadEdgeState    = "2";

#CurrentPath
my $script_dir;
my $conf;
my @data;
my $sessionName;
my @area_setting;
my $actions;

my $up              = "up";
my $down            = "down";
my $left            = "left";
my $right           = "right";
my $action          = "action";
my $pressCode       = "press";

my $defaultAction   = "default";



#if($verbose == 1) {
#    print "File name ". __FILE__ . "\n";
#    print "Line Number " . __LINE__ ."\n";
#    print "Package " . __PACKAGE__ ."\n";
#}


#reads and parses the arguments
while(my $ARGV = shift){
    ### $ARGV
    if ($ARGV eq $distanceArgument){
        if ($ARGV[0] > 0){
            $baseDist = $baseDist * $ARGV[0];
            ### $baseDist
            shift;
        }else{
            print "Set a value greater than 0\n";
            usage();
        }
    }elsif ($ARGV eq $pollingTimeArgument){
        if ($ARGV[0] > 0){
            $pollingInterval = $ARGV[0];
            ### $pollingInterval
            shift;
        }else{
            print "Set a value greater than 0\n";
            usage();
        }
    }elsif ($ARGV eq $verboseArgument) {
        $verbose = 1;
    }elsif ($ARGV eq $verboseLevelTwoArgument) {
        $verbose = 2;
    }elsif ($ARGV eq $verboseLevelThreeArgument) {
        $verbose = 3;
    }elsif ($ARGV eq $disableWhileTypingArgument) {
        $disableWhileTyping = $setDisableWhileTyping;
    }elsif ($ARGV eq $disableTimeAfterTypingArgument) {
        if ($ARGV[0] > 0){
            $disableAfterTypingTime = $setDisableAfterTypingTime . $ARGV[0];
            ### touchpad disable time interval
            shift;
        }else{
            usage();
        }
    }else{
        usage();
    }
}

&setupSynClientDaemon($disableWhileTyping, $disableAfterTypingTime);
&loadScrollDelta();
&initSynclient();

open (area_setting, "synclient -l | grep Edge | grep -v -e Area -e Motion -e Scroll | ")or die "can't synclient -l";
@area_setting = <area_setting>;
close(fileHundle);

&setupTouchpadEdges();
&setupThresholds();
&setupEdges();



### @area_setting
### $touchpadHeight
### $touchpadWidth
### $xMinThreshold
### $yMinThreshold
### $innerEdgeLeft
### $innerEdgeRight
### $innerEdgeTop
### $innerEdgeBottom

#load config
$script_dir = $FindBin::Bin;#CurrentPath

if($verbose == 1) {
    print "Script file: ".($script_dir."/".$confFileName)."\n";
}

$conf = json_file_to_perl ($script_dir."/".$confFileName);

#$conf = require $script_dir."/".$confFileName;

open (fileHundle, "pgrep -lf ^gnome-session |")or die "can't pgrep -lf ^gnome-session";
@data = <fileHundle>;
$sessionName = (split "session=", $data[0])[1];
close(fileHundle);
chomp($sessionName);
# If $session_name is empty (gnome-session doesn't work), try to find it with $DESKTOP_SESSION
if (not length $sessionName){
    open (desktopSession, 'echo $DESKTOP_SESSION |')or die 'can\'t echo $DESKTOP_SESSION';
    $sessionName = <desktopSession>;
    close(desktopSession);
    chomp($sessionName);
}

if($verbose == 1) {
    print "session name is $sessionName\n";
}

$sessionName = ("$sessionName" ~~ $conf) ? "$sessionName" : 'other';
if($verbose == 1) {
    print "getting configuration $sessionName\n";
}

### $sessionName
$actions = $conf->{"$sessionName"};

# session variables (possible actions)
my @swipe3Right         = split $confSplitter, ($conf->{$sessionName}->{swipe3}->{light}->{right});




#definition of actions when force is used


my @xHist1 = ();                # x coordinate history (1 finger)
my @yHist1 = ();                # y coordinate history (1 finger)
my @zHist1 = ();                # z coordinate history (1 finger)

my @xHist2 = ();                # x coordinate history (2 fingers)
my @yHist2 = ();                # y coordinate history (2 fingers)
my @zHist2 = ();                # z coordinate history (2 fingers)

my @xHist3 = ();                # x coordinate history (3 fingers)
my @yHist3 = ();                # y coordinate history (3 fingers)
my @zHist3 = ();                # z coordinate history (3 fingers)

my @xHist4 = ();                # x coordinate history (4 fingers)
my @yHist4 = ();                # y coordinate history (4 fingers)
my @zHist4 = ();                # z coordinate history (4 fingers)

my @xHist5 = ();                # x coordinate history (5 fingers)
my @yHist5 = ();                # y coordinate history (5 fingers)
my @zHist5 = ();                # z coordinate history (5 fingers)

my $axis = 0;
my $rate = 0;
my $touchState = 0;             # touchState={0/1/2} 0=notSwiping, 1=Swiping, 2=edgeSwiping
my $lastTime = 0;               # time monitor for TouchPad event reset
my $eventTime = 0;              # ensure enough time has passed between events
my @eventString = ("default");  # the event to execute



my $currWind = GetInputFocus();
die "couldn't get input window" unless $currWind;
open(INFILE,"synclient -m $pollingInterval |") or die "can't read from synclient";

#main loop
#detects events and handles each
#time     x    y   z f  w  l r u d m     multi  gl gm gr gdx gdy
while(my $line = <INFILE>){
    chomp($line);
    my($time, $x, $y, $z, $f, $w, $l, $r, $u, $d, $m) = split " ", $line;
    
    #ignore header lines
    next if($time =~ /time/);

    #if time reset
    if($time - $lastTime > 5){
        &initSynclient();
    }
    $lastTime = $time;
    $axis = 0;
    $rate = 0;

    if($f == 1){ # 1 finger
        if($touchState == 0){
            if(($x < $innerEdgeLeft)or($innerEdgeRight < $x)
                or
                ($y < $innerEdgeTop)or($y >$innerEdgeBottom)){
                $touchState = $touchpadEdgeState;
                &switchTouchPad("Off");
            }else{
                $touchState = $touchpadNotEdgeState;
            }
        }
        cleanHist(2 ,3 ,4 ,5);
        if ($touchState == $touchpadEdgeState){
            push @xHist1, $x;
            push @yHist1, $y;
            push @zHist1, $z;
            $axis = getAxis(\@xHist1, \@yHist1, \@zHist1, 2, 0.1);
            if($axis eq $xAxis){
                $rate = getRate(@xHist1);
                $touchState = $touchpadEdgeState;
            }elsif($axis eq $yAxis){
                $rate = getRate(@yHist1);
                $touchState = $touchpadEdgeState;
            }elsif($axis eq $zAxis){
                #$rate = getRate(@zHist1);
                #touchState = $touchpadEdgeState;
                #print "x axis detected\n";
            }
        }

    }elsif($f == 2){ # 2 fingers
        if($touchState == 0){
            if(
                ($x < $innerEdgeLeft) or ($innerEdgeRight  < $x)
                or
                ($y < $innerEdgeTop)or($y >$innerEdgeBottom)
            ){
                $touchState = $touchpadEdgeState;
                ### $touchState
            }else{
                $touchState = $touchpadNotEdgeState;
            }
        }
        cleanHist(1, 3, 4, 5);
        push @xHist2, $x;
        push @yHist2, $y;
        push @zHist2, $z;
        $axis = getAxis(\@xHist2, \@yHist2, \@zHist2, 2, 0.1);
        if($axis eq $xAxis){
            $rate = getRate(@xHist2);
        }elsif($axis eq $yAxis){
            $rate = getRate(@yHist2);
        }elsif($axis eq $zAxis){
            #$rate = getRate(@zHist2);


            #print "z axis detected\n";
            $axis = getAxis(\@xHist2, \@yHist2, \@zHist2, 30, 0.5);
            if($axis eq $zAxis){
                #$rate = getRate(@zHist2);
            }
        }

    }elsif($f == 3){ # 3 fingers
        if($touchState == 0 ){
            if(($y < $innerEdgeTop)or($innerEdgeBottom < $y)
                or
              ($y < $innerEdgeTop)or($y >$innerEdgeBottom)
              ){
                $touchState = $touchpadEdgeState;
                ### $touchState
            }else{
                $touchState = $touchpadNotEdgeState;
            }
        }
        cleanHist(1, 2, 4, 5);
        push @xHist3, $x;
        push @yHist3, $y;
        push @zHist3, $z;
        $axis = getAxis(\@xHist3, \@yHist3, \@zHist3, 5, 0.5);
        if($axis eq $xAxis){
            $rate = getRate(@xHist3);
        }elsif($axis eq $yAxis){
            $rate = getRate(@yHist3);
        }elsif($axis eq $zAxis){
            #$rate = getRate(@zHist3);


            #print "x axis detected\n";
            $axis = getAxis(\@xHist3, \@yHist3, \@zHist3, 30, 0.5);
            if($axis eq $zAxis){
                #$rate = getRate(@zHist3);
            }
        }

    }elsif($f == 4){ # 4 fingers
        if($touchState == 0 ){
            if(($y < $innerEdgeTop)or($innerEdgeBottom < $y)
                or
                ($y < $innerEdgeTop)or($y >$innerEdgeBottom)
            ){
                $touchState = $touchpadEdgeState;
                ### $touchState
            }else{
                $touchState = $touchpadNotEdgeState;
            }
        }
        cleanHist(1, 2, 3, 5);
        push @xHist4, $x;
        push @yHist4, $y;
        push @zHist4, $z;
        $axis = getAxis(\@xHist4, \@yHist4, \@zHist4, 5, 0.5);
        if($axis eq $xAxis){
            $rate = getRate(@xHist4);
        }elsif($axis eq $yAxis){
            $rate = getRate(@yHist4);
        }elsif($axis eq $zAxis){
            #$rate = getRate(@zHist4);


            #print "x axis detected\n";
            $axis = getAxis(\@xHist4, \@yHist4, \@zHist4, 30, 0.5);
            if($axis eq $zAxis){
                #$rate = getRate(@zHist4);
            }
        }

    }elsif($f == 5){ # 5 fingers
        if($touchState == 0 ){
            if(($y < $innerEdgeTop)or($innerEdgeBottom < $y)
                or
                ($y < $innerEdgeTop)or($y >$innerEdgeBottom)
            ){
                $touchState = $touchpadEdgeState;
                ### $touchState
            }else{
                $touchState = $touchpadNotEdgeState;
            }
        }
        cleanHist(1, 2, 3 ,4);
        push @xHist5, $x;
        push @yHist5, $y;
        push @zHist5, $z;
        $axis = getAxis(\@xHist5, \@yHist5, \@zHist5, 5, 0.5);
        if($axis eq $xAxis){
            $rate = getRate(@xHist5);
        }elsif($axis eq $yAxis){
            $rate = getRate(@yHist5);
        }elsif($axis eq $zAxis){
            #$rate = getRate(@zHist5);
        }
    }else{
        cleanHist(1, 2, 3, 4, 5);
        if($touchState > 0){
            $touchState = 0; #touchState Reset
            &switchTouchPad("On");
        }
    }


#detect action
    if ($axis ne 0){
        @eventString = setEventString($f,$axis,$rate,$touchState, $z, $l, $actions);
        cleanHist(1, 2, 3, 4, 5);
    }

# only process one event per time window
    if( $eventString[0] ne "default" ){
        ### ne default
        if( abs($time - $eventTime) > $eventTimeWindow ){
            ### $time - $eventTime got: $time - $eventTime
            $eventTime = $time;
            PressKey $_ foreach(@eventString);
            ReleaseKey $_ foreach(reverse @eventString);
            ### @eventString
        }# if enough time has passed
        @eventString = ("default");
    }#if non default event
}#synclient line in
close(INFILE);

sub getSubActions{
    return split $confSplitter, (@_[0]);
}



##shows the usage and exits
sub usage{
    print "
        Available Options
        $distanceArgument RATE
            RATE sensitivity to swipe
            RATE > 0, default value is 1
        $pollingTimeArgument INTERVAL
            INTERVAL how often synclient monitor changes to the touchpad state
            INTERVAL > 0, default value is 10 (ms)
        $verboseArgument
            Verbose
        $verboseLevelTwoArgument
            Verbose level set to 2.
        $verboseLevelThreeArgument
            Verbose level set to 3.
        $disableWhileTypingArgument [time to reactivate threshold]
            Disables the touchpad while writing on the keyboard
        \n";
    exit(0);
}

sub loadScrollDelta{
    open (Scroll_setting, "synclient -l | grep ScrollDelta | grep -v -e Circ | ")or die "can't synclient -l";
    my @Scroll_setting = <Scroll_setting>;
    close(fileHundle);

    $vertScrollDelta  = (split "= ", $Scroll_setting[0])[1];
    $horizScrollDelta = (split "= ", $Scroll_setting[1])[1];

    if($verbose == 1) {
        print "Vertical   Scroll Delta: $vertScrollDelta\n";
        print "Horizontal Scroll Delta: $horizScrollDelta\n";
        print "\n";
    }
}

sub setupSynClientDaemon{
    # add syndaemon setting
    system("syndaemon -m $pollingInterval $disableWhileTyping $disableAfterTypingTime -d &");
}

###init
sub initSynclient{
    `synclient VertScrollDelta=$vertScrollDelta HorizScrollDelta=$horizScrollDelta ClickFinger3=1 TapButton3=2`;
}

sub setupTouchpadEdges{
    $leftEdge   = (split "= ", $area_setting[0])[1];
    $rightEdge  = (split "= ", $area_setting[1])[1];
    $topEdge    = (split "= ", $area_setting[2])[1];
    $bottomEdge = (split "= ", $area_setting[3])[1];

    if($verbose == 3) {
        print "Left Edge   : $leftEdge\n";
        print "Right Edge  : $rightEdge\n";
        print "Top Edge    : $topEdge\n";
        print "Bottom Edge : $bottomEdge\n";
        print "\n";
    }
}

sub setupTouchpadSize{
    $touchpadHeight = abs($topEdge - $bottomEdge);
    $touchpadWidth = abs($leftEdge - $rightEdge);

    if($verbose == 3) {
        print "Touchpad Height : $touchpadHeight\n";
        print "Touchpad Width  : $touchpadWidth\n";
        print "\n";
    }
}

sub setupThresholds{
    $xMinThreshold = $touchpadWidth * $baseDist;
    $yMinThreshold = $touchpadHeight * $baseDist;

    if($verbose == 3) {
        print "X Minimum threshold : $xMinThreshold\n";
        print "Y Minimum threshold : $yMinThreshold\n";
        print "\n";
    }
}

sub setupEdges{
    $innerEdgeLeft   = $leftEdge   + $xMinThreshold/2;
    $innerEdgeRight  = $rightEdge  - $xMinThreshold/2;
    $innerEdgeTop    = $topEdge    + $yMinThreshold;
    $innerEdgeBottom = $bottomEdge - $yMinThreshold;

    if($verbose == 3) {
        print "Inner Edge Left   : $innerEdgeLeft\n";
        print "Inner Edge Right  : $innerEdgeRight\n";
        print "Inner Edge Top    : $innerEdgeTop\n";
        print "Inner Edge Bottom : $innerEdgeBottom\n";
        print "\n";
    } 
}

sub switchTouchPad{
    open(TOUCHPADOFF,"synclient -l | grep TouchpadOff |") or die "can't read from synclient";
    my $TouchpadOff = <TOUCHPADOFF>;
    close(TOUCHPADOFF);
    chomp($TouchpadOff);
    my $TouchpadOff = (split "= ", $TouchpadOff)[1];
    ### $TouchpadOff
    my $switch_flag = shift;
    ### $switch_flag
    if($switch_flag eq 'Off'){
        if($TouchpadOff eq '0'){
            `synclient TouchpadOff=1`;
        }
    }elsif($switch_flag eq 'On'){
        if($TouchpadOff ne '0' ){
            `synclient TouchpadOff=0`;
        }
    }
}



sub getAxis{
    my($xHist, $yHist, $zHist, $max, $thresholdRate)=@_;
    if(@$xHist > $max or @$yHist > $max or @$zHist > $max){
        my $x0 = @$xHist[0];
        my $y0 = @$yHist[0];
        my $z0 = @$zHist[0];
        my $xmax = @$xHist[$max];
        my $ymax = @$yHist[$max];
        my $zmax = @$zHist[$max];
        my $xDist = abs( $x0 - $xmax );
        my $yDist = abs( $y0 - $ymax );
        my $zDist = abs( $z0 - $zmax );
        if($xDist > $yDist){
            if($xDist > $xMinThreshold * $thresholdRate){
                return $xAxis;
            }
        }elsif($yDist > $zDist){ #probably should multiply zDist by some value
            if($yDist > $yMinThreshold * $thresholdRate){
                return $yAxis;
            }
        }else{
            if($zDist > $zMinThreshold * $thresholdRate){
                return $zAxis;
            }
        }
    }
    return 0;
}

sub getRate{
    my @hist = @_;
    my @srt    = sort {$a <=> $b} @hist;
    my @revSrt = sort {$b <=> $a} @hist;
    if( "@srt" eq "@hist" ){
        return $positiveMovement;
    }elsif( "@revSrt" eq "@hist" ){
        return $negativeMovement;
    }#if forward or backward
    return 0;
}

sub cleanHist{
    while(my $arg = shift){
        if($arg == 1){
            @xHist1 = ();
            @yHist1 = ();
            @yHist1 = ();
        }elsif($arg == 2){
            @xHist2 = ();
            @yHist2 = ();
            @zHist2 = ();
        }elsif($arg == 3){
            @xHist3 = ();
            @yHist3 = ();
            @zHist3 = ();
        }elsif($arg == 4){
            @xHist4 = ();
            @yHist4 = ();
            @zHist4 = ();
        }elsif($arg == 5){
            @xHist5 = ();
            @yHist5 = ();
            @zHist5 = ();
        }
    }
}




#return @eventString $_[0]
sub setEventString{
    my($f, $axis, $rate, $touchState, $force, $pressed, $actions)=@_;
    my $curr = $actions;

    #does not have a supported desktop version
    if(!(defined $curr)) {
        return $defaultAction;
    }

    $curr = $curr->{"$f"};
    print "$f fingers ";

    if($f < 0) {
        print "\nGot negative number of fingers detected.\n";
        return $defaultAction;
    }

    #does not support that number of fingers (not configured)
    if(!(defined $curr)) {
        print "\n No configuration for the selected number of fingers\n";
        return $defaultAction;
    }

    if($pressed == "1") {
        print " pressed\n";
        $curr = $curr->{"$pressCode"};
        cleanHist(1, 2, 3, 4, 5);
        return getSubActions($curr->{"$action"});
    }

    if($touchState eq $touchpadEdgeState) {
        print "$edgeSwipeCode ";
        $curr = $curr->{"$edgeSwipeCode"};
    } elsif ($touchState eq $touchpadNotEdgeState) {
        print "$swipeCode ";
        $curr = $curr->{"$swipeCode"};
    } elsif($touchState eq $touchpadDefaultState) {
        print "$longPressCode ";
        $curr = $curr->{"$longPressCode"};
        #long press does not have a direction
        if(!(defined $curr)) {
            print "\n No configuration for the current touch state\n";
            return $defaultAction;
        }
        cleanHist(1, 2, 3, 4, 5);
        return getSubActions($curr->{"$action"});
    } else {
        print "\nOperation not supported\n";
        return $defaultAction;
    }

    #does not support the current touchpad state(not configured)
    if(!(defined $curr)) {
        print "\n No configuration for the current touch state\n";
        return $defaultAction;
    }

    if($force <= $forceThreshold) {
        print "light ";
        $curr = $curr->{"light"};
    } else {
        print "forced ";
        $curr = $curr->{"forced"};
    }

    #does not support the multiple forces (not configured)
    if(!(defined $curr)) {
        print "\n No configuration for force detection\n";
        return $defaultAction;
    }

    if($axis eq $xAxis) {
        if($rate eq $positiveMovement){
            print "right\n";
            $curr = $curr->{"$right"};
         }elsif($rate eq $negativeMovement){
            print "left\n";
            $curr = $curr->{"$left"};
        }
    } elsif($axis eq $yAxis) {
        if($rate eq $positiveMovement){
            print "down\n";
            $curr = $curr->{"$down"};
         }elsif($rate eq $negativeMovement){
            print "up\n";
            $curr = $curr->{"$up"};
        }
    } elsif ($axis eq $zAxis) {
        print "z axis operations not totally supported\n";
        return $defaultAction;
    }

    #does not support the current touchpad state(not configured)
    if(!(defined $curr)) {
        print "\n No configuration for the selected axis\n";
        return $defaultAction;
    }

    return getSubActions($curr->{"$action"});
}






