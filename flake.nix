{
  description = "Command-line interface for latex-online service";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";
  inputs.laton = {
    flake = false;
    url = "https://raw.githubusercontent.com/aslushnikov/latex-online/master/util/latexonline";
  };



  outputs = { self , nixpkgs , laton }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      # supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      supportedSystems = [ "x86_64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlays.default ]; });

    in

    {

      # A Nixpkgs overlay.
      overlays.default = final: prev: {

        laton = with final; stdenvNoCC.mkDerivation rec {
          name = "laton-${version}";

          buildInputs = with nixpkgsFor.${system}; [ curl ];

          unpackPhase = ":";
          
          buildPhase = ''
            cat ${laton} >> laton
            chmod 755 laton 
          '';

          installPhase =
            ''
              mkdir -p $out/bin
              cp laton $out/bin/laton
            '';
        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        rec {
          inherit (nixpkgsFor.${system}) laton;
          default = laton;
        });
      
    };
}
