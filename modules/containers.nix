# Docker runs as the rootful container engine. Members of the `docker` group
# in hosts/*/default.nix can use its socket, and Distrobox uses this engine too.
{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  environment.systemPackages = with pkgs; [
    docker-compose # Standalone `docker-compose` command.
    lazydocker # TUI for containers, images, and volumes.
    distrobox
  ];
}
