Froggum Svg Editor
==========

Froggum is a Cairo-based XVG editor for making elementary OS app icons.
(Other uses are allowed.)

*Note: Froggum is a work in progress. Nothing is guaranteed to work, least
of all this README. Eerything will be updated as I get to it.*

Overview
--------

Froggum allows users to create icons in any of the standard icon sizes
(16, 24, 32, 48, 64, and 128), or a custom shape and size. These are
specified in the "New" submenu. Clicking "Custom" will open a small dialog
to choose width and height.

All icons are automatically saved when changed to their associated
filename. A newly created icon is associated with a temporary file in the
app's data directory, but can be given a name and a save point using "Save
As".

Editing
-------

All icons are built out of paths. These paths are shown in the sidebar,
including a name (default "Path N"), the shape of the path, and the fill
and stroke colors. (Gradient support will probably be added in a later
version.)

Paths may be rearranged in the sidebar, resulting in a change in the
drawing order. Paths at the top are drawn last, on top of all paths below.

### Segments

Each path is built out of one or more segments. A segment corresponds to a
single Cairo path command. Some (`Move` and `Close Path`) are used
implicitly and are not added directly. `Line`, `Arc`, and `Curve` are all
used by the user to define the shape of the path.

A segment may be appended to a path by pressing the corresponding button
along the top of the editor view. After creation, a segment may be deleted
or changed to a different shape by right-clicking.

A segment may be selected by clicking on it. When selected, control handles
appear around the segment. These handles are dependent on the type of
segment.

#### `Line` Segments

`Line` segments display only two handles: one on each end of the line. Both
can be dragged to update the line (and the other segment attached to that
point).

#### `Curve` Segments

`Curve` segments display four handles: one at each end of the curve and one
at each of the control points. Froggum only uses cubic curves, not
quadratic. As with `Line` segments, each handle can be dragged to change
the shape of the curve.

#### `Arc` Segments

`Arc` segments are slightly different from `Line` and `Curve` segments.
Rather than being defined by a small collection of points, `Arc` segments
rely on an ellipse. As such, selecting an `Arc` segment will display a
bounding box of the base ellipse, which can be rotated or scaled by
dragging control points at the corners. Handles are also displayed at the
start and end points of the arc, which can be dragged along the ellipse to
change the section of the ellipse shown by the arc.

#### Context Menu

Right-clicking on any segment will bring up a context menu. This will
always contain options to delete the segment or to change it to another
type. `Arc` segments also have the option to switch the arc direction.


