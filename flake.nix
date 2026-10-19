{
  description = "PicoGK geometry kernel with a natively built Linux runtime";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    runtime = {
      url = "git+https://github.com/reimundklain/PicoGKRuntime?ref=fix-narrow-band&submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      runtime,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems =
        function: nixpkgs.lib.genAttrs systems (system: function nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        picogk-runtime = runtime.packages.${pkgs.stdenv.hostPlatform.system}.default;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.picogk-runtime;
      });

      devShells = forAllSystems (
        pkgs:
        let
          picogkRuntime = self.packages.${pkgs.stdenv.hostPlatform.system}.picogk-runtime;
          dotnetSdk = pkgs.dotnetCorePackages.sdk_9_0;
        in
        {
          default = pkgs.mkShell {
            packages = [
              dotnetSdk
              pkgs.nixfmt
            ];

            DOTNET_ROOT = "${dotnetSdk}/share/dotnet";
            DOTNET_CLI_TELEMETRY_OPTOUT = "1";

            # fontconfig is required by SkiaSharp.NativeAssets.Linux (libSkiaSharp.so).
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
              picogkRuntime
              pkgs.fontconfig
            ];
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
