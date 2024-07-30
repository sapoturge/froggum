public interface Container : Undoable, Updatable, Transformed {
    public signal void path_selected (Element? element);
    public signal void move_above (Element element, Command command);
    public signal void move_below (Element element, Command command);

    public struct ModelUpdate {
        uint position;
        uint removals;
        Element[] elements;
        Element? selection;
    }

    protected class ElementSignalManager {
        public ulong set_size;
        public ulong update;
        public ulong select;
        public ulong request_delete;
        public ulong swap_up;
        public ulong swap_down;
        public ulong path_selected;
        public ulong move_above;
        public ulong move_below;
        public ulong request_duplicate;
        public ulong replace;
        public ulong add_command;
    }

    public abstract Gtk.TreeListModel tree { get; set; }
    public GLib.ListModel model {
        get {
            return tree.model;
        }
    }

    public abstract Element? selected_child { get; protected set; }
    protected abstract Gee.Map<Element, ElementSignalManager> signal_managers { get; set; }

    // This has to be abstract so it exists in the child classes
    public abstract ModelUpdate updator { set; }
    protected void do_update (ModelUpdate value) {
        if (selected_child != value.selection && selected_child != null) {
            selected_child.select (false);
        }

        for (int i = 0; i < value.removals; i++) {
            var element = (Element) model.get_item (value.position + i);
            if (element != null) {
                remove_signal_manager (element);
            }
        }

        foreach (var elem in value.elements) {
            setup_signal_manager (elem);
        }

        ((ListStore) model).splice (value.position, value.removals, (GLib.Object[]) value.elements);
        if (value.selection != null && value.selection != selected_child) {
            value.selection.select (true);
        }

        update ();
    }

    public ListModel? get_children (Object object) {
        var con = object as Container;
        if (con != null) {
            return con.model;
        } else {
            return null;
        }
    }

    protected int save_children (Xml.Node* root_node, Xml.Node* defs, int pattern_index) {
        var index = model.get_n_items () - 1;
        var elem = model.get_item (index) as Element;
        while (elem != null) {
            pattern_index = elem.add_svg (root_node, defs, pattern_index);
            index -= 1;
            elem = model.get_item (index) as Element;
        }

        return pattern_index;
    }

    protected void load_elements (Xml.Node* parent, Gee.HashMap<string, Pattern> patterns) {
        for (Xml.Node* iter = parent->children; iter != null; iter = iter->next) {
            if (iter->name == "path") {
                var path = new Path.from_xml (iter, patterns);
                add_element (path);
            } else if (iter->name == "circle") {
                var circle = new Circle.from_xml (iter, patterns);
                add_element (circle);
            } else if (iter->name == "g") {
                var g = new Group.from_xml (iter, patterns);
                add_element (g);
            } else if (iter->name == "rect") {
                var rect = new Rectangle.from_xml (iter, patterns);
                add_element (rect);
            } else if (iter->name == "ellipse") {
                var ellipse = new Ellipse.from_xml (iter, patterns);
                add_element (ellipse);
            } else if (iter->name == "line") {
                var line = new Line.from_xml (iter, patterns);
                add_element (line);
            } else if (iter->name == "polyline") {
                var line = new Polyline.from_xml (iter, patterns);
                add_element (line);
            } else if (iter->name == "polygon") {
                var polygon = new Polygon.from_xml (iter, patterns);
                add_element (polygon);
            }
        }
    }

    protected void add_element (Element element) {
        setup_signal_manager (element);

        ((ListStore) model).insert (0, element);

        update ();
    }

    private void setup_signal_manager (Element element) {
        element.set_size (transform.width, transform.height);
        var signal_manager = new ElementSignalManager ();
        signal_manager.set_size = set_size.connect ((width, height) => {
            element.set_size (width, height);
        });
        signal_manager.update = element.update.connect (() => { update (); });
        signal_manager.select = element.select.connect ((selected) => {
            if (selected) {
                selected_child = element;
                path_selected (element);
            } else {
                selected_child = null;
                path_selected (null);
            }
        });

        signal_manager.request_delete = element.request_delete.connect (() => {
            uint index;
            element.select (false);
            if (((ListStore) model).find (element, out index)) {
                var command = new Command ();
                var remove_update = ModelUpdate () {
                    position = index,
                    elements = {},
                    removals = 1,
                    selection = null,
                };
                var replace_update = ModelUpdate () {
                    position = index,
                    elements = { element },
                    removals = 0,
                    selection = element,
                };
                updator = remove_update;
                command.add_value (this, "updator", remove_update, replace_update);
                add_command (command);
            }
        });

        signal_manager.swap_up = element.swap_up.connect ((into) => {
            uint index;
            if (((ListStore) model).find (element, out index)) {
                var previous = model.get_item (index - 1) as Element;
                if (previous != null) {
                    var cont = previous as Container;
                    if (into && cont != null) {
                        var command = new Command ();
                        var removal = ModelUpdate () {
                            position = index,
                            elements = {},
                            removals = 1,
                            selection = null,
                        };
                        var replace = ModelUpdate () {
                            position = index,
                            elements = { element },
                            removals = 0,
                            selection = element,
                        };
                        command.add_value (this, "updator", removal, replace);
                        cont.insert_bottom (element, command);
                    } else {
                        var command = new Command ();
                        var swapped = ModelUpdate () {
                            position = index - 1,
                            elements = { element, previous },
                            removals = 2,
                            selection = element,
                        };
                        var unswapped = ModelUpdate () {
                            position = index - 1,
                            elements = { previous, element },
                            removals = 2,
                            selection = element,
                        };
                        updator = swapped;
                        command.add_value (this, "updator", swapped, unswapped);
                        add_command (command);
                    }
                } else {
                    var command = new Command ();
                    var removal = ModelUpdate () {
                        position = index,
                        elements = {},
                        removals = 1,
                        selection = null,
                    };
                    var replaced = ModelUpdate () {
                        position = index,
                        elements = { element },
                        removals = 0,
                        selection = element,
                    };
                    command.add_value (this, "updator", removal, replaced);
                    move_above (element, command);
                }
            }
        });

        signal_manager.swap_down = element.swap_down.connect ((into) => {
            uint index;
            if (((ListStore) model).find (element, out index)) {
                var next = model.get_item (index + 1) as Element;
                if (next != null) {
                    var cont = next as Container;
                    if (into && cont != null) {
                        var command = new Command ();
                        var removal = ModelUpdate () {
                            position = index,
                            elements = {},
                            removals = 1,
                            selection = null,
                        };
                        var replace = ModelUpdate () {
                            position = index,
                            elements = { element },
                            removals = 0,
                            selection = element,
                        };
                        command.add_value (this, "updator", removal, replace);
                        cont.insert_top (element, command);
                    } else {
                        var command = new Command ();
                        var swapped = ModelUpdate () {
                            position = index,
                            elements = { next, element },
                            removals = 2,
                            selection = element,
                        };
                        var unswapped = ModelUpdate () {
                            position = index,
                            elements = { element, next },
                            removals = 2,
                            selection = element,
                        };
                        updator = swapped;
                        command.add_value (this, "updator", swapped, unswapped);
                        add_command (command);
                    }
                } else {
                    var command = new Command ();
                    var removal = ModelUpdate () {
                        position = index,
                        elements = {},
                        removals = 1,
                        selection = null,
                    };
                    var replaced = ModelUpdate () {
                        position = index,
                        elements = { element },
                        removals = 0,
                        selection = element,
                    };
                    command.add_value (this, "updator", removal, replaced);
                    move_below (element, command);
                }
            }
        });

        signal_manager.request_duplicate = element.request_duplicate.connect (() => {
            uint index;
            if (((ListStore) model).find (element, out index)) {
                var duplicated = element.copy ();
                var command = new Command ();
                var add_duplicate = ModelUpdate () {
                    position = index,
                    elements = { duplicated },
                    removals = 0,
                    selection = duplicated,
                };
                var remove_duplicate = ModelUpdate () {
                    position = index,
                    elements = { },
                    removals = 1,
                    selection = element,
                };
                updator = add_duplicate;
                command.add_value (this, "updator", add_duplicate, remove_duplicate);
                add_command (command);
            }
        });

        signal_manager.replace = element.replace.connect ((new_elem) => {
            uint index;
            if (((ListStore) model).find (element, out index)) {
                var command = new Command ();
                var swap_in = ModelUpdate () {
                    position = index,
                    elements = { new_elem },
                    removals = 1,
                    selection = new_elem,
                };
                var swap_out = ModelUpdate () {
                    position = index,
                    elements = { element },
                    removals = 1,
                    selection = element,
                };
                updator = swap_in;
                command.add_value (this, "updator", swap_in, swap_out);
                add_command (command);
            }
        });

        signal_manager.add_command = element.add_command.connect ((c) => add_command (c));

        var cont = element as Container;
        if (cont != null) {
            signal_manager.path_selected = cont.path_selected.connect ((elem) => {
                if (elem == null) {
                    selected_child = null;
                } else {
                    selected_child = element;
                }

                path_selected (elem);
            });

            signal_manager.move_above = cont.move_above.connect ((elem, command) => {
                uint index;
                if (((ListStore) model).find (cont, out index)) {
                    var add = ModelUpdate () {
                        position = index,
                        elements = { elem },
                        removals = 0,
                        selection = elem,
                    };
                    var remove = ModelUpdate () {
                        position = index,
                        elements = {},
                        removals = 1,
                        selection = null,
                    };
                    command.add_value (this, "updator", add, remove);
                    command.apply ();
                    add_command (command);
                }
            });

            signal_manager.move_below = cont.move_below.connect ((elem, command) => {
                uint index;
                if (((ListStore) model).find (cont, out index)) {
                    var add = ModelUpdate () {
                        position = index + 1,
                        elements = { elem },
                        removals = 0,
                        selection = elem,
                    };
                    var remove = ModelUpdate () {
                        position = index + 1,
                        elements = {},
                        removals = 1,
                        selection = null,
                    };
                    command.add_value (this, "updator", add, remove);
                    command.apply ();
                    add_command (command);
                }
            });
        }

        signal_managers.set (element, signal_manager);
    }

    private void remove_signal_manager (Element element) {
        if (element == selected_child) {
            element.select (false);
        }
        ElementSignalManager manager;
        signal_managers.unset (element, out manager);
        if (manager != null) {
            disconnect (manager.set_size);
            element.disconnect (manager.update);
            element.disconnect (manager.select);
            element.disconnect (manager.request_delete);
            element.disconnect (manager.request_duplicate);
            element.disconnect (manager.swap_up);
            element.disconnect (manager.swap_down);
            element.disconnect (manager.replace);
            element.disconnect (manager.add_command);
            var cont = element as Container;
            if (cont != null) {
                cont.disconnect (manager.path_selected);
                cont.disconnect (manager.move_above);
                cont.disconnect (manager.move_below);
            }
        }
    }

    private void insert_top (Element element, Command command) {
        var insert = ModelUpdate () {
            position = 0,
            elements = { element },
            removals = 0,
            selection = element,
        };
        var remove = ModelUpdate () {
            position = 0,
            elements = {},
            removals = 1,
            selection = null,
        };
        command.add_value (this, "updator", insert, remove);
        command.apply ();
        add_command (command);
    }

    private void insert_bottom (Element element, Command command) {
        var insert = ModelUpdate () {
            position = model.get_n_items (),
            elements = { element },
            removals = 0,
            selection = element,
        };
        var remove = ModelUpdate () {
            position = model.get_n_items (),
            elements = {},
            removals = 1,
            selection = null,
        };
        command.add_value (this, "updator", insert, remove);
        command.apply ();
        add_command (command);
    }

    protected void draw_children (Cairo.Context cr) {
        var index = model.get_n_items () - 1;
        var elem = model.get_item (index) as Element;
        while (elem != null) {
            elem.transform.apply (cr);
            elem.draw (cr);
            cr.restore ();
            index -= 1;
            elem = model.get_item (index) as Element;
        }
    }

    public void draw_selected_child (Cairo.Context cr, double zoom) {
        if (selected_child != null) {
            selected_child.transform.apply (cr);
            var new_zoom = zoom;
            selected_child.transform.update_distance (zoom, out new_zoom);
            selected_child.draw_controls (cr, new_zoom);
            cr.restore ();
            if (selected_child.transform_enabled) {
                selected_child.transform.draw_controls (cr, zoom);
            }
        }
    }

    public bool clicked_child (double x, double y, double tolerance, out Element? element, out Segment? segment, out Handle? handle) {
        if (selected_child != null) {
            if (selected_child.transform_enabled) {
                if (selected_child.transform.check_controls (x, y, tolerance, out handle)) {
                    element = selected_child;
                    segment = null;
                    return true;
                }
            }

            var new_x = x, new_y = y;
            var new_tolerance = tolerance;
            Handle inner_handle;
            selected_child.transform.update_point (x, y, out new_x, out new_y);
            selected_child.transform.update_distance (tolerance, out new_tolerance);
            selected_child.check_controls (new_x, new_y, new_tolerance, out inner_handle);
            selected_child.clicked (new_x, new_y, new_tolerance, out element, out segment);
            if (inner_handle != null) {
                if (element == null) {
                    element = selected_child;
                }

                handle = new TransformedHandle (element.title, inner_handle, element.transform);
                return true;
            } else if (element != null) {
                handle = null;
                return true;
            }
        }

        handle = null;
        var index = 0;
        var elem = model.get_item (index) as Element;
        while (elem != null) {
            if (elem.visible) {
                var new_x = x, new_y = y;
                var new_tolerance = tolerance;
                elem.transform.update_point (x, y, out new_x, out new_y);
                elem.transform.update_distance (tolerance, out new_tolerance);
                if (elem.clicked (new_x, new_y, new_tolerance, out element, out segment)) {
                    return true;
                }
            }

            index += 1;
            elem = model.get_item (index) as Element;
        }

        element = null;
        segment = null;
        return false;
    }

    public virtual bool has_selected () {
        return selected_child != null;
    }

    public virtual void deselect () {
        if (selected_child != null) {
            selected_child.select (false);
        }
    }

    public virtual bool clicked_handle (double x, double y, double tolerance, out Handle? handle) {
        if (selected_child != null) {
            if (selected_child.transform_enabled) {
                if (selected_child.transform.check_controls (x, y, tolerance, out handle)) {
                    return true;
                }
            }

            var new_x = x, new_y = y;
            var new_tolerance = tolerance;
            Handle inner_handle;
            selected_child.transform.update_point (x, y, out new_x, out new_y);
            selected_child.transform.update_distance (tolerance, out new_tolerance);
            if (selected_child.check_controls (new_x, new_y, new_tolerance, out inner_handle)) {
                handle = new TransformedHandle (selected_child.title, inner_handle, selected_child.transform);
                return true;
            }
        }

        handle = null;
        return false;
    }
}
