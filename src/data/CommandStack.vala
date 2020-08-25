public class CommandStack : Object {
    private Array<Command> commands;
    private int current_index;
    
    public CommandStack () {}
    
    construct {
        commands = new Array<Command> ();
        current_index = 0;
    }
    
    public void add_command (Command command) {
        commands.remove_range (current_index, commands.length - current_index);
        commands.append_val (command);
        command.apply ();
        current_index += 1;
    }
    
    public void undo () {
        if (current_index > 0) {
            current_index -= 1;
            var command = commands.index (current_index);
            command.revert ();
        }
    }
    
    public void redo () {
        if (current_index < commands.length) {
            var command = commands.index (current_index);
            command.apply ();
            current_index += 1;
        }
    }
}
