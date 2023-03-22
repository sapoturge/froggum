public interface Container : Undoable {
    public struct ModelUpdate {
        int position;
        Element? element;
        bool insert;
    }

    public abstract Gtk.TreeListModel model { get; set; }

    public ModelUpdate updator {
        set {
            if (value.element == null) {
                ((ListStore) model.model).remove (value.position);
            } else if (value.insert == true) {
                ((ListStore) model.model).insert (value.position, value.element);
            } else {
                ((ListStore) model.model).remove (value.position);
                ((ListStore) model.model).insert (value.position, value.element);
            }
        }
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
        var index = 0;
        var elem = model.get_item (index) as Element;
        while (elem != null) {
            pattern_index = elem.add_svg (root_node, defs, pattern_index);
            index += 1;
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
        ((ListStore) model.model).append (element);
    }

    protected void draw_children (Cairo.Context cr) {
        var index = 0;
        var row = model.get_item (index) as Gtk.TreeListRow;
        while (row != null) {
            var elem = row.item as Element;
            elem.transform.apply (cr);
            elem.draw (cr);
            cr.restore ();
            index += 1;
            row = model.get_item (index) as Gtk.TreeListRow;
        }
    }
}