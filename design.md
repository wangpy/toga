# Design notes

## Notes for `toga.tosc`

The orientation of the grid is the orientation of the connect button.
The script attached to the orientation button will change the orientation
of the connect button, as well as changing the orientation lights.

The OSC message `/toga_connection` has a send variant and a receive variant.
When sent from the norns and received by TouchOSC the argument is the
connect button's `x` value.
When sent from TouchOSC and received by the norns the argument is the
connect button's orientation.

## Notes for `lib/togagrid.lua`

`old_buffer` is what's been sent to the grid; `new_buffer` is the old buffer
with any changes. This allows only changes to be sent on a refresh.

`dest` is a list of tables, mapping IP address to port number, one for each
connected grid.

`orientation` is what the grid says its orientation is. 0 = north, 1 = east,
2 = south, 3 = west. This is the orientation enumeration in TouchOSC.
Regardless of how many grids are connected, there is only one orientation
for all of them. Beware that the semantics is different from that used by
`grid:rotation(val)` which is used to tell a (real)
grid what orientation it should assume. There, the argument is
0 = 0 degrees (east), 1 = 90 degrees (north), etc.
