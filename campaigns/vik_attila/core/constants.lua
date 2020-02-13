return {
    __write_output_to_logfile = true, -- write log files
    __allow_test_buttons = true, --allows the pressing of the F9-F12 key scripted test functions
    __should_output_ui = false, --outputs UI object details on click. Spams the log a bit so leave it off when not doing UI work.
    __log_game_objects = false, --Logs all game object types to a series of files. For use once per patch.
    __should_output_save_load = false, --Outputs the internals of the functions which save and load objects. Only necessary for debugging.
    __do_not_save_or_load = false, --turns off saving and loading lua values completely.
    __no_fog = false, --turn off fog of war.
    __log_settlements = true, -- log information about settlements when they are selected
    __log_characters = true, -- log information about characters when they are selected
    __unit_size_scalar = 0.5 --0.5 is shieldwalls default. Controls unit sizes for population counts.
}