public class Tutorial : Gtk.Popover {
    public enum Step {
        SCROLL,
        CLICK,
        DRAG,
        DONE
    }
    
    public Step step { get; private set; }
    
    private Gtk.Stack stack;
    private Gtk.Widget click;
    private Gtk.Widget drag;
    private Gtk.Widget done;
    private Gtk.Button skip;
    
    public void next_step () {
        if (step == SCROLL) {
            step = CLICK;
            stack.visible_child = click;
        } else if (step == CLICK) {
            step = DRAG;
            stack.visible_child = drag;
        } else if (step == DRAG) {
            step = DONE;
            stack.visible_child = done;
            skip.label = "Finish";
        } else {
            popdown ();
        }
    }
    
    public void skip_tutorial () {
        popdown ();
    }
    
    construct {
        var scroll = new Gtk.Label (_("Scroll to zoom"));
        
        click = new Gtk.Label (_("Double click on a path to select it"));
        
        drag = new Gtk.Label (_("Drag a circle to change the path"));
        
        done = new Gtk.Label (_("Keep editing!"));
        
        skip = new Gtk.Button.with_label (_("Skip Tutorial"));
        skip.clicked.connect(() => { skip_tutorial (); });
        
        stack = new Gtk.Stack ();
        stack.add_named (scroll, "scroll");
        stack.add_named (click, "click");
        stack.add_named (drag, "drag");
        stack.add_named (done, "done");
        
        stack.visible_child = scroll;
        
        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        button_box.pack_end (skip);
        
        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        layout.pack_start (stack);
        layout.pack_start (button_box);
        layout.show_all ();
        add (layout);
        
        modal = false;
        step = SCROLL;
    }
}
