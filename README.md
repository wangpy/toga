
# toga
TouchOSC grid and arc controller for monome norns

## Demo Video
https://www.instagram.com/p/CS4JRtonRD7/

## Instruction
 1. Install **toga**: from maiden type: `;install https://github.com/wangpy/toga` 
 2. Edit script you want to use **toga** with (similar to [how to edit script to add midigrid support](https://norns.community/en/authors/jaggednz/midigrid#how-to-edit-a-script))
	1. Find occurence of "grid.connect()" in the script code and insert the following line above:
		```
		local grid = util.file_exists(_path.code.."toga") and include "toga/lib/togagrid" or grid
		```
		 - If the script is already edited to support **midigrid**, you can add the support on midigrid library script file: add the line above to line 1 in **code/midigrid/lib/midigrid.lua**. When no midigrid-supported device is connected, toga grid will be initialized.
	2. Find occurence of "grid.connect()"  in the script code and insert the following line above:
		```
		local arc = util.file_exists(_path.code.."toga") and include "toga/lib/togaarc" or arc
		```
	3. Select the edited script on norns to load
 3. Download **toga.tosc** controller file and import to TouchOSC (new version, not working with Mk1).
 4. Set up connections to norns:
	1. Choose UDP
	2. Look up norns IP address in **SYSTEM** -> **WIFI** and input to **Host** field
	3. Input 10111 to **Send Port**
	4. Input 8002 to **Receive Port** (any unused port number should work)
5. Run the TouchOSC controller (by clicking Play button).
6. Tap the upper-right green button to connect to norns. The green button should light up and the controller should be running.
7. (Optional) Adding default TouchOSC client address:
	1. Open **code/toga/lib/togagrid.lua** file
	2. Find the line `-- UNCOMMENT to add default touchosc client`
	3. Remove leading `--` in the line below, and edit the IP address in the line.
	4. Open **code/toga/lib/togaarc.lua** file and repeat the step 2 and 3.
	5. Reload the script on norns. Now **toga** will automatically connect to the TouchOSC controller when the script is loaded.

## Forum
https://llllllll.co/t/toga-touchosc-grid-and-arc-controller-for-monome-norns/47902
