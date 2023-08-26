{

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let

      # System types to support.
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        });
    in
    {

      # A Nixpkgs overlay.
      overlays.default = final: prev: {
        woodpecker-pipeline = with final; writeText "pipeline" (builtins.toJSON
          {
            configs = [

              {
                name = "Build and push hello-world";
                data = (builtins.toJSON {
                  labels.backend = "local";
                  pipeline = [
                    {
                      name = "Setup Attic";
                      image = "bash";
                      commands = [
                        "attic login lounge-rocks https://cache.lounge.rocks $ATTIC_KEY --set-default"
                      ];
                      secrets = [ "attic_key" ];
                    }
                    {
                      name = "Build hello-world";
                      image = "bash";
                      commands = [
                        "nix build 'nixpkgs#hello'"
                      ];
                    }
                    {
                      name = "Push to Cache";
                      image = "bash";
                      commands = [
                        "attic push lounge-rocks:nix-cache result"
                      ];
                    }
                  ];
                });
              }
              # {
              #   name = "Docker pipeline";
              #   data = (builtins.toJSON {
              #     labels.backend = "docker";
              #     platform = "linux/arm64";
              #     steps.build = {
              #       image = "debian";
              #       commands = [
              #         ''echo "This is the build step"''
              #       ];
              #     };
              #   });
              # }
              # {
              #   name = "Exec pipeline";
              #   data = (builtins.toJSON {
              #     labels.backend = "local";
              #     platform = "linux/arm64";
              #     steps.build = {
              #       image = "bash";
              #       commands = [
              #         ''echo "This is the build step"''
              #       ];
              #     };
              #   });
              # }
              {
                name = "Pipeline from string";
                data = ''
                  {
                    "labels": {
                      "backend": "local"
                    },
                    "pipeline": [
                      {
                        "commands": [
                          "attic login lounge-rocks https://cache.lounge.rocks $ATTIC_KEY --set-default"
                        ],
                        "image": "bash",
                        "name": "Setup Attic",
                        "secrets": [ "attic_key" ]
                      },
                      {
                        "commands": [
                          "nix build '.#woodpecker-pipeline'",
                          "attic push lounge-rocks:nix-cache result"
                        ],
                        "image": "bash",
                        "name": "Build and push hello-world"
                      }
                    ]
                  }
                '';
              }

              # {
              #   name = "flake-pipeline";
              #   data = ''
              #     when:
              #       branch: main
              #       event: push
              #     labels:
              #       backend: local

              #     pipeline:
              #     - name: Test commands
              #       image: bash
              #       commands:
              #         - echo "HELLO WORLD"
              #         - echo $HOME
              #         - pwd
              #   '';
              # }
              # {
              #   name = "a second pipeline";
              #   data = (builtins.toJSON {
              #     labels.backend = "local";
              #     pipeline = [
              #       {
              #         name = "Test from toJSON";
              #         image = "bash";
              #         commands = [
              #           "echo 'hello from the other side'"
              #         ];
              #       }
              #     ];
              #   });
              # }
            ];
          });
      };

      # Package
      packages = forAllSystems
        (system: {
          inherit (nixpkgsFor.${system}) woodpecker-pipeline;
        });

    };
}
