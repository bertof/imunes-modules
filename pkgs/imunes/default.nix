{ lib
, tcl
, tcllib
, tk
, fetchFromGitHub
, tclx
, makeDesktopItem

, version ? "2.4.0"
, sha256 ? "sha256-6reA4mh5Ub8phz6v4wrlcDeEg3Ycn96i95ZUROtnHhU="
}:

let
  tclLibraries = [ tcl tcllib tclx tk ];
in
tcl.mkTclDerivation rec {
  pname = "imunes";
  inherit version;

  src = fetchFromGitHub {
    owner = "imunes";
    repo = "imunes";
    rev = "v${version}";
    inherit sha256;
  };

  buildInputs = tclLibraries;

  makeFlags = [ "PREFIX=$(out)" "DESTDIR=" ];

  postInstall = ''
    wrapProgram $out/bin/imunes \
    --prefix TCLLIBPATH : "${lib.makeLibraryPath tclLibraries}" \
    --prefix PATH : "${lib.makeBinPath [ tcl ]}"
  '';

  desktopItem = makeDesktopItem {
    name = "imunes";
    desktopName = "Imunes";
    genericName = "Network Simulator";
    comment = meta.description;
    icon = "imunes";
    exec = "pkexec imunes";
    categories = [ ];
  };

  meta = {
    homepage = "https://imunes.net";
    description = "Integrated Multiprotocol Network Emulator/Simulator";
    inherit version;
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.bertof ];
    platforms = lib.platforms.linux;
  };
}

