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
        woodpecker-pipeline = with final; writeText "pipeline" ''
{
  "configs": [
    {
      "name": "central-override",
      "data": "labels:\n  backend: local\n\npipeline:\n- name: Test commands\n  image: bash\n  commands:\n    - echo "HELLO WORLD"\n    - nix --version\n    - nix doctor\n    - nix store ping  \n    - whereis nix\n    - which nix\n    - nix run 'nixpkgs#hello'\n    - nix flake show\n    - nix run\n
"
    }
  ]
}



     
        '';
      };

      # Package
      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) woodpecker-pipeline;
      });

    };
}
