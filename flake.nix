{
  description = "NixOS configs - kyurem (Framework 13 AMD AI 370)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma settings such as shortcuts, panels, and KWin live here.
    # Grab settings from a running desktop with:
    #   nix run github:nix-community/plasma-manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Encrypted secrets live in secrets/ and unlock during activation
    # through the host SSH key. Edit them with `sops secrets/secrets.yaml`.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpak management module.
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Prebuilt nix-index data powers comma (`, foo`) and command-not-found
    # suggestions without a long local indexing job.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Numtide refreshes these AI agent harnesses daily. Its cache targets
    # Numtide's pinned unstable release, so it keeps its own nixpkgs input.
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      # Keeps additional hosts nice and short to add.
      mkHost = name: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/${name} ];
      };
    in
    {
      nixosConfigurations = {
        kyurem = mkHost "kyurem";
      };

      # `nix fmt` tidies the whole tree through treefmt and nixfmt.
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
