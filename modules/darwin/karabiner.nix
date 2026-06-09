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
          devices = [];
          virtual_hid_keyboard.keyboard_type_v2 = "ansi";
          complex_modifications = {
            rules = [
              {
                description = "Swap right_control and right_option for Polish characters";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "right_control";
                      modifiers.optional = [ "any" ];
                    };
                    to = [ { key_code = "right_option"; } ];
                  }
                  {
                    type = "basic";
                    from = {
                      key_code = "right_option";
                      modifiers.optional = [ "any" ];
                    };
                    to = [ { key_code = "right_control"; } ];
                  }
                ];
              }
            ];
          };
        }
      ];
    };
  };
}
