# xSwipe

xSwipe is multitouch gesture recognizer.
This script make your linux PC able to recognize swipes like a Macbook.
In this version, a software force detection is used.
Now you can have multiple different gestures, depending on the force you use.
For now, only light force and heavy forces are supported.

The force is calculated by the area of touch of each of your fingers on the touchpad, producing a z coordinate (that is used as force).

## Usage

Before running the script, you must first do some preparations.

  1. Download xSwipe
  2. Install X11::GUITest
  3. Install JSON::Parse
  4. Enable SHMConfig

### 1. Download xSwipe
Type below code, download xSwipe from github

    $ cd ~
    $ wget https://github.com/guilhermemtr/xSwipe/archive/master.zip
    $ unzip master.zip

### 2. Install X11::GUITest

To install libx11-guitest-perl from synaptic package manager
Or run the script on the terminal run as

    $ sudo apt-get install libx11-guitest-perl

---
#### NOTE: If using Ubuntu14.04, or later
##### Install older version synaptics driver that is compatible with xSwipe.

```bash
$ sudo apt-get install -y git build-essential libevdev-dev autoconf automake libmtdev-dev xorg-dev xutils-dev libtool
$ sudo apt-get remove -y xserver-xorg-input-synaptics
$ git clone https://github.com/Chosko/xserver-xorg-input-synaptics.git
$ cd xserver-xorg-input-synaptics
$ ./autogen.sh
$ ./configure --exec_prefix=/usr
$ make
$ sudo make install
```
---

### 3. Enable SHMConfig

Open /etc/X11/xorg.conf.d/50-synaptics.conf with your favorite text editor and edit it to enable SHMConfig

    $ sudo gedit /etc/X11/xorg.conf.d/50-synaptics.conf

**NOTE**:You will need to create the /etc/X11/xorg.conf.d/ directory and create 50-synaptics.conf if it doesn't exist yet.
     `$ sudo mkdir /etc/X11/xorg.conf.d/`

##### /etc/X11/xorg.conf.d/50-synaptics.conf

    Section "InputClass"
    Identifier "evdev touchpad catchall"
    Driver "synaptics"
    MatchDevicePath "/dev/input/event*"
    MatchIsTouchpad "on"
    Option "Protocol" "event"
    Option "SHMConfig" "on"
    EndSection

To reflect SHMConfig, restart your session.

That's it for preparation.

## Run xSwipe

To run xSwipe, type below code on terminal.

    $ perl ~/xSwipe-master/xSwipe.pl

**Note:You should run xSwipe.pl in same directory as "default.json" .**

You can use "swipe" with 3 or 4 fingers, they can call an event.
Additionally, some gestures are avilable.

* *edge-swipe* : swipe with 2 fingers from outside edge.
* *long-press* : hold pressure for 0.5 seconds with 3 or 4 fingers.

### Option

*   `-d RATE` :
      *RATE* is sensitivity to swipe.Default value is 1.
      Shorten swipe-length by half (e.g.,`$ perl xSwipe.pl -d 0.5`)
*   `-m INTERVAL` :
      *INTERVAL* is how often synclient monitor changes to the touchpad state.
      Default value is 10(ms).
      Set 50ms as monitoring-span. (e.g.,`$ perl xSwipe.pl -m 50`)

## Customize
For this version, this tutorial might be outdated. However you can always use the given example. I will publish more examples and create a wiki page with the same objective soon.
You can customize the settings for gestues to edit eventKey.cfg.
Please check this article, ["How to customize gesture"](https://github.com/iberianpig/xSwipe/wiki/Customize-eventKey.cfg).

### Bindable gestures
* 3/4/5 fingers swipe
* 2/3/4/5 fingers long-press
* 2/3/4/5 fingers edge-swipe
* For each of the presented bindable gestures, you can select what to do in case of a light touch or a heavy one.

### Example shortcut keys
* go back/forward on browser (Alt+Left, Alt+Right)
* open/close a tab on browser (Ctrl+t/Ctrl+w)
* move tabs (Ctrl+Tab, Ctrl+Shift+Tab)
* move workspaces (Alt+Ctrl+Lert, Alt+Ctrl+Right, Alt+Ctrl+Up, Alt+Ctrl+Down)
* move a window (Alt+F7)
* open launcher (Alt+F8)
* open a terminal (Ctrl+Alt+t)
* close a window (Alt+F4)

Please let me know if you have any questions about this program.
If you have any suggestions feel free to send me a message.

#TODO
* Add press detection (and distinguish from force touches)
* Add pinch detection
* Add configuration files for major environments (gnome, kde, mate, xfce, etc) and a default one.
* Add support for multiple touch forces, being able to configure it (by the JSON file)


