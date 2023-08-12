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
                name = "flake-pipeline";
                data = ''
                  labels:
                    backend: local

                  pipeline:
                  - name: Test commands
                    image: bash
                    commands:
                      - echo "HELLO WORLD"
                      - echo $HOME
                      - pwd
                '';
              }
              {
                name = "a second pipeline";
                data = (builtins.toJSON {
                  labels.backend = "local";
                  pipeline = [
                    {
                      name = "Test from THE PULL REQUEST";
                      image = "bash";
                      commands = [
                        "echo 'hello from the other side'"
                      ];
                    }
                  ];
                });
              }
            ];
          });
      };

      # Package
      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) woodpecker-pipeline;
      });

    };
}
