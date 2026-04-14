# Git configuration
{
  username,
  email,
  gitName ? username,
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = gitName;
      user.email = email;
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.autocrlf = "input";
    };
  };

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      light = false;
      line-numbers = true;
    };
  };
}
