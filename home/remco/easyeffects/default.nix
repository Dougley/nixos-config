{ ... }:

# EasyEffects runs in the background with the Cab's_20Fav output preset.
# Home Manager configures the service and ships the preset declaratively.

{
  services.easyeffects = {
    enable = true;
    preset = "cabs-20fav";
    extraPresets = {
      cabs-20fav = builtins.fromJSON (builtins.readFile (./. + "/Cab's_20Fav.json"));
    };
  };
}
