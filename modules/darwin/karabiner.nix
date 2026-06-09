{ username, ... }: {
  home-manager.users.${username} = { ... }: {
    home.file.".config/karabiner/karabiner.json".text = builtins.toJSON {
      global = {
        check_for_updates_on_startup = true;
        show_in_menu_bar = true;
        show_profile_name_in_menu_bar = false;
      };
      profiles = [
        {
          name = "Default profile";
          selected = true;
          parameters.delay_milliseconds_before_open_device = 1000;
          simple_modifications = [];
          fn_function_keys = [];
          complex_modifications.rules = [];
          virtual_hid_keyboard.keyboard_type_v2 = "ansi";
          devices = [
            {
              # USB Gaming Keyboard (SEMICO) - VID: 6700, PID: 38405
              identifiers = {
                is_keyboard = true;
                vendor_id = 6700;
                product_id = 38405;
              };
              simple_modifications = [
                {
                  from.key_code = "right_command";
                  to = [ { key_code = "right_control"; } ];
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
