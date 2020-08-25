public class Command : Object {
    private Array<Object> objects;
    private Array<string> properties;
    private Array<Value?> new_values;
    private Array<Value?> old_values;
    
    public Command () {
    }
    
    construct {
        objects = new Array<Object> ();
        properties = new Array<string> ();
        new_values = new Array<Value?> ();
        old_values = new Array<Value?> ();
    }
    
    public void add_value (Object obj, string prop, Value new_value, Value old_value) {
        objects.append_val (obj);
        properties.append_val (prop);
        new_values.append_val (new_value);
        old_values.append_val (old_value);
    }
    
    public void apply () {
        for (int i = 0; i < objects.length; i++) {
            var object = objects.index (i);
            var prop = properties.index (i);
            object.@set (prop, new_values.index (i));
        }
    }
    
    public void revert () {
        for (int i = 0; i < objects.length; i++) {
            var object = objects.index (i);
            var prop = properties.index (i);
            var old_value = old_values.index (i);
            object.@set (prop, old_value);
        }
        old_values = null;
    }
}
