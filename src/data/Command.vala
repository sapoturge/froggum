public class Command : Object {
    private Array<Object> objects;
    private Array<string> properties;
    private Array<Value?> new_values;
    private Array<Value?> old_values;
    
    public Command () {
    }
    
    public void add_value (Object obj, string prop, Value new_value) {
        objects.append_val (obj);
        properties.append_val (prop);
        new_values.append_val (new_value);
    }
    
    public void apply () {
        old_values = new Array<Value?> ();
        for (int i = 0; i < objects.length; i++) {
            var object = objects.index (i);
            var prop = properties.index (i);
            Value old_value;
            object.@get (prop, out old_value);
            old_values.append_val (old_value);
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
