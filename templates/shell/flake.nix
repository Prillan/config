{
  description = "A very basic shell flake";

  outputs = { self, nixpkgs }: {
    devShells.x86_64-linux.default =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        python = pkgs.python3.withPackages (pp: [
          pp.requests
        ]);
      in
      pkgs.mkShell {
        name = "A shell";
        buildInputs = [
          python
        ];
      };
  };
}
