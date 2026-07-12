{ ... }:

# Plasma settings managed through plasma-manager. Set things up in the
# Plasma GUI, then capture the useful changes with
#   nix run github:nix-community/plasma-manager
# (rc2nix) and add them here.
#
# With overrideConfig set to false, this file applies its declared settings
# and leaves the rest to the GUI. Set it to true when this file holds the
# complete Plasma setup.

{
  programs.plasma = {
    enable = true;

    # A few examples to adapt or replace with rc2nix output:
    #
    # workspace = {
    #   clickItemTo = "select";           # Select files and folders on click.
    #   colorScheme = "BreezeDark";
    # };
    #
    # shortcuts."services/org.kde.konsole.desktop"."_launch" = "Meta+Return";
    #
    # kwin.effects.translucency.enable = true;
  };
}
