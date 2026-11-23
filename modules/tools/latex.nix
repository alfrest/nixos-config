# `minted` shells out to `pygmentize`, so Pygments is installed alongside
# TeX Live; the lab build passes `-shell-escape` to XeLaTeX.
{ ... }:

{
  flake.nixosModules.latex =
    { pkgs, ... }:
    {
      home-manager.users.alfrest.home.packages = [
        (pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-medium
            collection-latexextra
            collection-pictures;
        })
        pkgs.python3Packages.pygments
      ];
    };
}
