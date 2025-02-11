{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bash;
  colors = builtins.mapAttrs (name: value: ''echo -n -e "\001\e[${builtins.toString value}m\002"'') {
    default = 0;
    black = 30;
    red = 31;
    green = 32;
    yellow = 33;
    blue = 34;
    magenta = 35;
    cyan = 36;
    light_gray = 37;
  };
  mkPrompt =
    name: script:
    if cfg.prompt.${name}.enable then
      "$(${pkgs.writeShellScript "bash_${name}_prompt" script})"
    else
      "";
  hostname_prompt = mkPrompt "hostname" ''
    ${colors.cyan}
    echo -n $(whoami)
    ${colors.default}
    echo -n "@"
    ${colors.blue}
    echo -n $(hostname)
  '';
  nix_prompt = mkPrompt "nix" ''
    if test -n "$IN_NIX_SHELL"; then
      ${colors.cyan}
      echo -n "<nix>"
    fi
  '';
  pwd_prompt = mkPrompt "pwd" ''
    ${colors.yellow}
    echo -n "$(pwd)"
  '';
  git_prompt = mkPrompt "git" (
    let
      git = "${cfg.prompt.git.package}/bin/git";
    in
    ''
      branch=$(echo -n "$(${git} rev-parse --abbrev-ref HEAD 2> /dev/null)")
      if test -n "$branch"; then
        ${colors.default}
        echo -n "($branch)"
      fi
    ''
  );
  prompt = pkgs.writeShellScript "bash_prompt" ''
    echo -n \
    ${hostname_prompt} \
    ${nix_prompt} \
    ${pwd_prompt} \
    ${git_prompt} \

    ${colors.default}
    echo -n "> "
  '';
in
{
  imports = [ ./blesh.nix ];
  options.bash = with lib; {
    enable = mkEnableOption "Bash module";
    package = mkOption {
      type = types.package;
      default = pkgs.bashInteractive;
      description = "What bash package to use";
    };
    prompt = {
      hostname = {
        enable = mkEnableOption "Enable hostname in prompt";
      };
      nix = {
        enable = mkEnableOption "Enable nix in prompt";
      };
      pwd = {
        enable = mkEnableOption "Enable cwd in prompt";
      };
      git = {
        enable = mkEnableOption "Enable git in prompt";
        package = mkOption {
          type = types.package;
          default = config.programs.git.package;
          description = "What git package to use";
        };
      };
    };
    nix_shell_preserve_prompt = mkEnableOption "Makes nix-shell keep PS1";
  };
  config = {
    programs.bash = lib.mkIf cfg.enable {
      enable = true;
      package = cfg.package;
      initExtra = ''
        PS1='$(${prompt})'
      '';
      sessionVariables = {
        NIX_SHELL_PRESERVE_PROMPT = if cfg.nix_shell_preserve_prompt then 1 else { };
      };
    };
  };
}
