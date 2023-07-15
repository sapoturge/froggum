public interface Container : Undoable, Updatable, Transformed {
    public signal void path_selected (Element? element);
    public signal void move_above (Element element, Command command);

    public struct ModelUpdate {
        uint position;
        uint removals;
        Element[] elements;
    }

    public abstract Gtk.TreeListModel tree { get; set; }
    public GLib.ListModel model {
        get {
            return tree.model;
        }
    }

    public abstract Element? selected_child { get; set; }

    // This has to be abstract so it exists in the child classes
    public abstract ModelUpdate updator { set; }
    protected void do_update (ModelUpdate value) {
        ((ListStore) model).splice (value.position, value.removals, (GLib.Object[]) value.elements);
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
        element.set_size (transform.width, transform.height);
        set_size.connect ((width, height) => {
            element.set_size (width, height);
        });
        element.update.connect (() => { update (); });
        element.select.connect ((selected) => {
            if (selected) {
                selected_child = element;
                path_selected (element);
            } else {
                selected_child = null;
                path_selected (null);
            }
        });

        element.request_delete.connect (() => {
            uint index;
            element.select (false);
            if (((ListStore) model).find (element, out index)) {
                var command = new Command ();
                var remove_update = ModelUpdate () {
                    position = index,
                    elements = {},
                    removals = 1
                };
                var replace_update = ModelUpdate () {
                    position = index,
                    elements = { element },
                    removals = 0
                };
                updator = remove_update;
                command.add_value (this, "updator", remove_update, replace_update);
                add_command (command);
            }
        });

        element.swap_up.connect (() => {
            uint index;
            if (((ListStore) model).find (element, out index)) {
                var previous = model.get_item (index - 1) as Element;
                if (previous != null) {
                    var command = new Command ();
                    var swapped = ModelUpdate () {
                        position = index - 1,
                        elements = { element, previous },
                        removals = 2,
                    };
                    var unswapped = ModelUpdate () {
                        position = index - 1,
                        elements = { previous, element },
                        removals = 2,
                    };
                    updator = swapped;
                    command.add_value (this, "updator", swapped, unswapped);
                    add_command (command);
                } else {
                    var command = new Command ();
                    var removal = ModelUpdate () {
                        position = index,
                        elements = {},
                        removals = 1,
                    };
                    var replaced = ModelUpdate () {
                        position = index,
                        elements = { element },
                        removals = 0,
                    };
                    command.add_value (this, "updator", removal, replaced);
                    move_above (element, command);
                }
            }
        });

        element.swap_down.connect (() => {
            uint index;
            if (((ListStore) model).find (element, out index)) {
                var next = model.get_item (index + 1) as Element;
                if (next != null) {
                    var command = new Command ();
                    var swapped = ModelUpdate () {
                        position = index,
                        elements = { next, element },
                        removals = 2,
                    };
                    var unswapped = ModelUpdate () {
                        position = index,
                        elements = { element, next },
                        removals = 2,
                    };
                    updator = swapped;
                    command.add_value (this, "updator", swapped, unswapped);
                    add_command (command);
                }
            }
        });

        var cont = element as Container;
        if (cont != null) {
            cont.path_selected.connect ((elem) => {
                selected_child = elem;
                path_selected (elem);
            });

            cont.move_above.connect ((elem, command) => {
                uint index;
                if (((ListStore) model).find (cont, out index)) {
                    var add = ModelUpdate () {
                        position = index,
                        elements = { elem },
                        removals = 0,
                    };
                    var remove = ModelUpdate () {
                        position = index,
                        elements = {},
                        removals = 1,
                    };
                    command.add_value (this, "updator", add, remove);
                    command.apply ();
                    add_command (command);
                }
            });
        }

        ((ListStore) model).insert (0, element);

        update ();
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
            selected_child.draw_transform (cr, zoom);
        }
    }

    public bool clicked_child (double x, double y, double tolerance, out Element? element, out Segment? segment) {
        var index = 0;
        var elem = model.get_item (index) as Element;
        while (elem != null) {
            var new_x = x, new_y = y;
            var new_tolerance = tolerance;
            elem.transform.update_point (x, y, out new_x, out new_y);
            elem.transform.update_distance (tolerance, out new_tolerance);
            if (elem.clicked (new_x, new_y, new_tolerance, out element, out segment)) {
                return true;
            }

            index += 1;
            elem = model.get_item (index) as Element;
        }

        element = null;
        segment = null;
        return false;
    }
}
