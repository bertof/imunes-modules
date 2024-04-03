{
  description = "Minimal flake environment";

  inputs = {
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = inputs@{ self, nixpkgs, ... }: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;
    imports = [ inputs.pre-commit-hooks-nix.flakeModule ];
    perSystem =
      { config
        # , self'
        # , inputs'
      , pkgs
        # , system
        # , lib
      , ...
      }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # # This sets `pkgs` to a nixpkgs with allowUnfree option set.
        # _module.args.pkgs = import nixpkgs {
        #   inherit system;
        #   config.allowUnfree = true;
        # };

        packages = {
          imunes = pkgs.callPackage ./pkgs/imunes { };
          imunes-2-3-0 = pkgs.callPackage ./pkgs/imunes {
            version = "2.3.0";
            sha256 = "sha256-Qf5u4oHnsJLGpDPRGSYbxDICL8MWiajxFb5/FADLfqc=";
          };
        };

        pre-commit.settings.hooks = {
          deadnix.enable = true;
          nixpkgs-fmt.enable = true;
          statix.enable = true;
        };

        devShells.default = pkgs.mkShell {
          shellHook = ''
            ${config.pre-commit.installationScript}
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      };

    flake = {
      overlays.imunes = final: _prev: {
        inherit (self.packages.${final.system}) imunes imunes-2-3-0;
      };

      nixosModules = {
        default_config = {
          # nixpkgs = { allowUnfree = true; };
          nix.extraOptions = "experimental-features = nix-command flakes";

          users.users.user = {
            isNormalUser = true;
            extraGroups = [ "network" "networkmanager" "wheel" "docker" ];
          };
        };

        graphical_environment = {
          services.xserver = {
            desktopManager.gnome.enable = true;
            displayManager.gdm.enable = true;
          };
        };

        imunes = { lib, pkgs, config, ... }:
          let cfg = config.virtualisation.imunes; in {
            options = {
              virtualisation.imunes = {
                enable = lib.mkEnableOption "imunes";
                package = lib.mkPackageOption pkgs.imunes-2-3-0;
              };
            };

            config = lib.mkIf cfg.enable {
              # Include Imunes overlay
              nixpkgs.overlays = [ self.overlays.imunes ];

              # Add Imunes to packages
              environment.systemPackages = [ cfg.package ];

              # Enable Open vSwitch
              virtualisation.vswitch = { enable = true; resetOnStart = true; };

              # Enable Docker
              virtualisation.docker.enable = true;
            };
          };
      };

      nixosConfigurations.computer-networks = nixpkgs.lib.nixosSystems {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.default_config
          self.nixosModules.imunes
          { virtualisation.imunes.enable = true; }
        ];
      };
    };
  };
}
