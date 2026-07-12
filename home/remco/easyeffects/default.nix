{ ... }:

# EasyEffects runs in the background with Framework 13 speaker EQ.
# Home Manager configures the service and ships the presets declaratively.
#
# Presets are the community-standard Framework tunings from
# https://github.com/ceiphr/ee-framework-presets (MIT), converted to
# the EasyEffects >= 7 schema ("equalizer" -> "equalizer#0"). The presets
# are read-only store symlinks, so they already use the current schema:
#   - fw13-kieran-levin: Framework's hardware lead's desk-friendly tuning
#   - fw13-lappy-mctopface: softer low mids for lap use
# Switch presets in the EasyEffects UI or with:
#   easyeffects -l fw13-lappy-mctopface
# The upstream "_louder" variants are left out because they can pop briefly
# during pause and play; see the upstream README.

{
  services.easyeffects = {
    enable = true;
    preset = "fw13-kieran-levin";
    extraPresets = {
      fw13-kieran-levin = builtins.fromJSON (builtins.readFile ./fw13-kieran-levin.json);
      fw13-lappy-mctopface = builtins.fromJSON (builtins.readFile ./fw13-lappy-mctopface.json);
    };
  };
}
