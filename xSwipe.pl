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
#debug
#use Smart::Comments;


my $forceThreshold = 70;


#list of arguments
my $distanceArgument               = "-d";
my $pollingTimeArgument            = "-m";
my $verboseArgument                = "-v";
my $verboseLevelTwoArgument        = "-vv";
my $verboseLevelThreeArgument      = "-vvv";
my $disableWhileTypingArgument     = "--disable-while-typing";
my $disableTimeAfterTypingArgument = "--disable-time";


#natural scrolling option
my $naturalScroll = 0;

#default basic distance
my $baseDist = 0.1;

#polling interval in milliseconds
my $pollingInterval = 10;

#default configuration file name
my $confFileName = "default.cfg";

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

my $touchpadHeight   = 0;
my $touchpadWidth    = 0;

my $xMinThreshold    = 0;
my $yMinThreshold    = 0;

my $innerEdgeLeft    = 0;
my $innerEdgeRight   = 0;
my $innerEdgeTop     = 0;
my $innerEdgeBottom  = 0;

#window for handling distinct events
my $eventTimeWindow = 0.2;




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
my @area_setting = <area_setting>;
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
my $script_dir = $FindBin::Bin;#CurrentPath
my $conf = require $script_dir."/".$confFileName;
open (fileHundle, "pgrep -lf ^gnome-session |")or die "can't pgrep -lf ^gnome-session";
my @data = <fileHundle>;
my $sessionName = (split "session=", $data[0])[1];
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


# session variables (possible actions)
my @swipe3Right         = split "/", ($conf->{$sessionName}->{swipe3}->{light}->{right});
my @swipe3Left          = split "/", ($conf->{$sessionName}->{swipe3}->{light}->{left});
my @swipe3Down          = split "/", ($conf->{$sessionName}->{swipe3}->{light}->{down});
my @swipe3Up            = split "/", ($conf->{$sessionName}->{swipe3}->{light}->{up});

my @swipe4Right         = split "/", ($conf->{$sessionName}->{swipe4}->{light}->{right});
my @swipe4Left          = split "/", ($conf->{$sessionName}->{swipe4}->{light}->{left});
my @swipe4Down          = split "/", ($conf->{$sessionName}->{swipe4}->{light}->{down});
my @swipe4Up            = split "/", ($conf->{$sessionName}->{swipe4}->{light}->{up});

my @swipe5Right         = split "/", ($conf->{$sessionName}->{swipe5}->{light}->{right});
my @swipe5Left          = split "/", ($conf->{$sessionName}->{swipe5}->{light}->{left});
my @swipe5Down          = split "/", ($conf->{$sessionName}->{swipe5}->{light}->{down});
my @swipe5Up            = split "/", ($conf->{$sessionName}->{swipe5}->{light}->{up});

my @edgeSwipe2Right     = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{light}->{right});
my @edgeSwipe2Left      = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{light}->{left});
my @edgeSwipe2Down      = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{light}->{down});
my @edgeSwipe2Up        = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{light}->{up});

my @edgeSwipe3Right     = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{light}->{right});
my @edgeSwipe3Left      = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{light}->{left});
my @edgeSwipe3Down      = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{light}->{down});
my @edgeSwipe3Up        = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{light}->{up});

my @edgeSwipe4Right     = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{light}->{right});
my @edgeSwipe4Left      = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{light}->{left});
my @edgeSwipe4Down      = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{light}->{down});
my @edgeSwipe4Up        = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{light}->{up});

my @longPress2 = split "/", ($conf->{$sessionName}->{swipe2}->{light}->{press});
my @longPress3 = split "/", ($conf->{$sessionName}->{swipe3}->{light}->{press});
my @longPress4 = split "/", ($conf->{$sessionName}->{swipe4}->{light}->{press});
my @longPress5 = split "/", ($conf->{$sessionName}->{swipe5}->{light}->{press});






#definition of actions when force is used


my @forceSwipe3Right         = split "/", ($conf->{$sessionName}->{swipe3}->{forced}->{right});
my @forceSwipe3Left          = split "/", ($conf->{$sessionName}->{swipe3}->{forced}->{left});
my @forceSwipe3Down          = split "/", ($conf->{$sessionName}->{swipe3}->{forced}->{down});
my @forceSwipe3Up            = split "/", ($conf->{$sessionName}->{swipe3}->{forced}->{up});

my @forceSwipe4Right         = split "/", ($conf->{$sessionName}->{swipe4}->{forced}->{right});
my @forceSwipe4Left          = split "/", ($conf->{$sessionName}->{swipe4}->{forced}->{left});
my @forceSwipe4Down          = split "/", ($conf->{$sessionName}->{swipe4}->{forced}->{down});
my @forceSwipe4Up            = split "/", ($conf->{$sessionName}->{swipe4}->{forced}->{up});

my @forceSwipe5Right         = split "/", ($conf->{$sessionName}->{swipe5}->{forced}->{right});
my @forceSwipe5Left          = split "/", ($conf->{$sessionName}->{swipe5}->{forced}->{left});
my @forceSwipe5Down          = split "/", ($conf->{$sessionName}->{swipe5}->{forced}->{down});
my @forceSwipe5Up            = split "/", ($conf->{$sessionName}->{swipe5}->{forced}->{up});

my @forceEdgeSwipe2Right     = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{forced}->{right});
my @forceEdgeSwipe2Left      = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{forced}->{left});
my @forceEdgeSwipe2Down      = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{forced}->{down});
my @forceEdgeSwipe2Up        = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{forced}->{up});

my @forceEdgeSwipe3Right     = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{forced}->{right});
my @forceEdgeSwipe3Left      = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{forced}->{left});
my @forceEdgeSwipe3Down      = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{forced}->{down});
my @forceEdgeSwipe3Up        = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{forced}->{up});

my @forceEdgeSwipe4Right     = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{forced}->{right});
my @forceEdgeSwipe4Left      = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{forced}->{left});
my @forceEdgeSwipe4Down      = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{forced}->{down});
my @forceEdgeSwipe4Up        = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{forced}->{up});

my @forceLongPress2 = split "/", ($conf->{$sessionName}->{swipe2}->{forced}->{press});
my @forceLongPress3 = split "/", ($conf->{$sessionName}->{swipe3}->{forced}->{press});
my @forceLongPress4 = split "/", ($conf->{$sessionName}->{swipe4}->{forced}->{press});
my @forceLongPress5 = split "/", ($conf->{$sessionName}->{swipe5}->{forced}->{press});




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
            if(($x < $innerEdgeLeft)or($innerEdgeRight < $x)){
                $touchState = 2;
                &switchTouchPad("Off");
            }else{
                $touchState = 1;
            }
        }
        cleanHist(2 ,3 ,4 ,5);
        if ($touchState == 2){
            push @xHist1, $x;
            push @yHist1, $y;
            $axis = getAxis(\@xHist1, \@yHist1, 2, 0.1);
            if($axis eq "x"){
                $rate = getRate(@xHist1);
                $touchState = 2;
            }elsif($axis eq "y"){
                $rate = getRate(@yHist1);
                $touchState = 2;
            }
        }

    }elsif($f == 2){ # 2 fingers
        if($touchState == 0){
            if(
                ($x < $innerEdgeLeft) or ($innerEdgeRight  < $x)
           # or ($y < $innerEdgeTop ) or ($innerEdgeBottom < $y)
            ){
                $touchState = 2;
                ### $touchState
            }else{
                $touchState = 1;
            }
        }
        cleanHist(1, 3, 4, 5);
        push @xHist2, $x;
        push @yHist2, $y;
        $axis = getAxis(\@xHist2, \@yHist2, 2, 0.1);
        if($axis eq "x"){
            $rate = getRate(@xHist2);
        }elsif($axis eq "y"){
            $rate = getRate(@yHist2);
        }elsif($axis eq "z"){
            $axis = getAxis(\@xHist2, \@yHist2, 30, 0.5);
            if($axis eq "z"){
            }
        }

    }elsif($f == 3){ # 3 fingers
        if($touchState == 0 ){
            if(($y < $innerEdgeTop)or($innerEdgeBottom < $y)){
                $touchState = 2;
                ### $touchState
            }else{
                $touchState = 1;
            }
        }
        cleanHist(1, 2, 4, 5);
        push @xHist3, $x;
        push @yHist3, $y;
        $axis = getAxis(\@xHist3, \@yHist3, 5, 0.5);
        if($axis eq "x"){
            $rate = getRate(@xHist3);
        }elsif($axis eq "y"){
            $rate = getRate(@yHist3);
        }elsif($axis eq "z"){
            $axis = getAxis(\@xHist3, \@yHist3, 30, 0.5);
            if($axis eq "z"){
            }
        }

    }elsif($f == 4){ # 4 fingers
        if($touchState == 0 ){
            if(($y < $innerEdgeTop)or($innerEdgeBottom < $y)){
                $touchState = 2;
                ### $touchState
            }else{
                $touchState = 1;
            }
        }
        cleanHist(1, 2, 3, 5);
        push @xHist4, $x;
        push @yHist4, $y;
        $axis = getAxis(\@xHist4, \@yHist4, 5, 0.5);
        if($axis eq "x"){
            $rate = getRate(@xHist4);
        }elsif($axis eq "y"){
            $rate = getRate(@yHist4);
        }elsif($axis eq "z"){
            $axis = getAxis(\@xHist4, \@yHist4, 30, 0.5);
            if($axis eq "z"){
            }
        }

    }elsif($f == 5){ # 5 fingers
        if($touchState == 0 ){
            if(($y < $innerEdgeTop)or($innerEdgeBottom < $y)){
                $touchState = 2;
                ### $touchState
            }else{
                $touchState = 1;
            }
        }
        cleanHist(1, 2, 3 ,4);
        push @xHist5, $x;
        push @yHist5, $y;
        $axis = getAxis(\@xHist5, \@yHist5, 5, 0.5);
        if($axis eq "x"){
            $rate = getRate(@xHist5);
        }elsif($axis eq "y"){
            $rate = getRate(@yHist5);
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
        @eventString = setEventString($f,$axis,$rate,$touchState);
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

    if($verbose == 1) {
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

    if($verbose == 1) {
        print "Touchpad Height : $touchpadHeight\n";
        print "Touchpad Width  : $touchpadWidth\n";
        print "\n";
    }
}

sub setupThresholds{
    $xMinThreshold = $touchpadWidth * $baseDist;
    $yMinThreshold = $touchpadHeight * $baseDist;

    if($verbose == 1) {
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

    if($verbose == 1) {
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
    my($xHist, $yHist, $max, $thresholdRate)=@_;
    if(@$xHist > $max or @$yHist > $max){
        my $x0 = @$xHist[0];
        my $y0 = @$yHist[0];
        my $xmax = @$xHist[$max];
        my $ymax = @$yHist[$max];
        my $xDist = abs( $x0 - $xmax );
        my $yDist = abs( $y0 - $ymax );
        if($xDist > $yDist){
            if($xDist > $xMinThreshold * $thresholdRate){
                return "x";
            }else{
                return "z";
            }
        }else{
            if($yDist > $yMinThreshold * $thresholdRate){
                return "y";
            }else{
                return "z";
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
        return "+";
    }elsif( "@revSrt" eq "@hist" ){
        return "-";
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
    my($f, $axis, $rate, $touchState)=@_;
    if($f == 2){ #two fingers
        if($axis eq "x"){
            if($touchState eq "2"){
                if($rate eq "+"){
                    print "edge swipe right 2 fingers\n";
                    return @edgeSwipe2Right;
                }elsif($rate eq "-"){
                    print "edge swipe left 2 fingers\n";
                    return @edgeSwipe2Left;
                }
            }
        }elsif($axis eq "y"){
            if($touchState eq "2"){
                if($rate eq "+"){
                    print "edge swipe down 2 fingers\n";
                    return @edgeSwipe2Down;
                }elsif($rate eq "-"){
                    print "edge swipe up 2 fingers\n";
                    return @edgeSwipe2Up;
                }
            }
        }elsif($axis eq "z"){
            if($rate eq "0"){
                if($touchState eq "1"){
                    print "long press with 2 fingers\n";
                    return @longPress2;
                }
            }
        }
    }elsif($f == 3){ #three fingers
        if($axis eq "x"){
            if($rate eq "+"){
                if($touchState eq "2"){
                    print "edge swipe right 3 fingers\n";
                    return @edgeSwipe3Right;
                }
                print "swipe right 3 fingers\n";
                return @swipe3Right;
            }elsif($rate eq "-"){
                if($touchState eq "2"){
                    print "edge swipe left 3 fingers\n";
                    return @edgeSwipe3Left;
                }
                print "swipe left 3 fingers\n";
                return @swipe3Left;
            }
        }elsif($axis eq "y"){
            if($rate eq "+"){
                if($touchState eq "2"){
                    print "edge swipe down 3 fingers\n";
                    return @edgeSwipe3Down;
                }
                return @swipe3Down;
            }elsif($rate eq "-"){
                if($touchState eq "2"){
                    print "edge swipe up 3 fingers\n";
                    return @edgeSwipe3Up;
                }
                print "swipe up 3 fingers\n";
                return @swipe3Up;
            }
        }elsif($axis eq "y"){
            if($rate eq "+"){
                if($touchState eq "2"){
                    print "edge swipe up 3 fingers\n";
                    return @edgeSwipe3Up;
                }
                print "swipe down 3 fingers\n";
                return @swipe3Down;
            }elsif($rate eq "-"){
                if($touchState eq "2"){
                    print "edge swipe down 3 fingers\n";
                    return @edgeSwipe3Down;
                }
            }
        }elsif($axis eq "z"){
            if($rate eq "0"){
                print "long press 3 fingers\n";
                return @longPress3;
            }
        }
    }elsif($f == 4){ #four fingers
        if($axis eq "x"){
            if($rate eq "+"){
                print "swipe right 4 fingers\n";
                return @swipe4Right;
            }elsif($rate eq "-"){
                print "swipe left 4 fingers\n";
                return @swipe4Left;
            }
        }elsif($axis eq "y"){
            if($rate eq "+"){
                if($touchState eq "2"){
                    print "edge swipe down 4 fingers\n";
                    return @edgeSwipe4Down;
                }
                print "swipe down 4 fingers\n";
                return @swipe4Down;
            }elsif($rate eq "-"){
                if($touchState eq "2"){
                    print "edge swipe up 4 fingers\n";
                    return @edgeSwipe4Up;
                }
                print "swipe up 4 fingers\n";
                return @swipe4Up;
            }
        }elsif($axis eq "z"){
            if($rate eq "0"){
                print "long press 4 fingers\n";
                return @longPress4;
            }
        }
    }elsif($f == 5){ #five fingers
        if($axis eq "x"){
            if($rate eq "+"){
                print "swipe right 5 fingers\n";
                return @swipe5Right;
            }elsif($rate eq "-"){
                print "swipe left 5 fingers\n";
                return @swipe5Left;
            }
        }elsif($axis eq "y"){
            if($rate eq "+"){
                print "swipe down 5 fingers\n";
                return @swipe5Down;
            }elsif($rate eq "-"){
                print "swipe up 5 fingers\n";
                return @swipe5Up;
            }
        }elsif($axis eq "z"){
            if($rate eq "0"){
                print "long press 5 fingers\n";
                return @longPress5;
            }
        }
    }
    return "default";
}






