---
---

# Using Froggum

## Getting Started

When you first open **Froggum**, you will see a page similar to this:

![New Tab Page](https://github.com/sapoturge/froggum/raw/master/screenshot.png)

*Yes, this is the wrong picture. I'll get the right one soon.*

Clicking on any of the buttons will get you a new icon.

**Warning: Opening files created in other applications is potentially dangerous.
Data loss may result.**

## Overview

1. Tab Bar

    All of your open icons are listed at the top, just like most other
    applications. **Froggum** automatically saves your open files, and remembers
    which files are open and even which one was last open.

2. Side Bar

    Along the side, there is a space similar to the Layers dialog in Photoshop
    or GIMP. Each path in the icon has an entry, including a small view of the
    path, a switch to control whether or not it is visible, the name of the path
    (which can be changed), and buttons to change the fill and stroke patterns.

    1. Mini-view

        The mini-view is just that: a view of the icon. Useful for when you want
        to see how edits affect the shape while zoomed in.

    2. Visibility switch

        The visibility switch controls whether or not the path is shown in the
        editor. It has no effect on the saved file.

    3. Name editor

        Each path has a name, saved as the `id` attribute in the file.
        Double-clicking willlet you change the name.

    4. Fill and Stroke buttons

        Clicking these buttons opens a dialog to let you choose the pattern used
        by the path. More on this later.

    Along the bottom of the side bar are five path manipulation buttons:

    * New path, which creates a new path and adds it to the image
    * Duplicate Path, which creates a copy of the current path and adds it
    * Move up/move down, which change the order of the paths
    * Delete path, which removes the current path.

3. Editor view

    The editor view is where all editing occurs. All visible paths are shown
    here, including any control handles for the selected path. You can scroll to
    zoom in or out, and drag to pan around.

## Editing

In the editor view, double-clicking on a path will select it. You can also
select a path by double-clicking on its row in the sidebar.

When a path is selected, it will be outlined in red, with a blue frame on some
segments, and red control handles will appear around any draggable point. All
control handles can be dragged around as you wish, and everything is
automatically saved.

Control-Z and Control-Y can be used for undo and redo, respectively.

Double-clicking off of a path will deselect it, and hide all controls.
