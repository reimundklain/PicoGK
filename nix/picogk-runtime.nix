{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  wayland-scanner,
  addDriverRunpath,
  boost,
  onetbb,
  c-blosc,
  zlib,
  libGL,
  libX11,
  libXcursor,
  libXext,
  libXi,
  libXinerama,
  libXrandr,
  libXrender,
  libXxf86vm,
  libxcb,
  libxkbcommon,
  libdecor,
  wayland,
  wayland-protocols,
}:

let
  libraryVersion = "26.2";
  libraryFile = "picogk.${libraryVersion}.so";

  glfwRuntimeLibraries = [
    libGL
    libX11
    libXcursor
    libXext
    libXi
    libXinerama
    libXrandr
    libXrender
    libXxf86vm
    libxcb
    libxkbcommon
    libdecor
    wayland
  ];
in
stdenv.mkDerivation {
  pname = "picogk-runtime";
  version = "${libraryVersion}.0";

  src = fetchFromGitHub {
    owner = "leap71";
    repo = "PicoGKRuntime";
    rev = "0f26321c18ed878a7820ef769c38fd5d49d39242";
    fetchSubmodules = true;
    hash = "sha256-QzXujOvkfQVSfmWYR6gvvbecMoOtn0EtxOdaopqReWw=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    wayland-scanner
    addDriverRunpath
  ];

  buildInputs = [
    boost
    onetbb
    c-blosc
    zlib
    wayland-protocols
  ]
  ++ glfwRuntimeLibraries;

  ninjaFlags = [ "picogk" ];

  installPhase = ''
    runHook preInstall

    install -Dm755 lib/picogk.so $out/lib/${libraryFile}
    ln -s ${libraryFile} $out/lib/picogk.so
    install -Dm644 -t $out/include ../API/*.h

    runHook postInstall
  '';

  # GLFW loads its windowing and OpenGL libraries with dlopen at runtime.
  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath glfwRuntimeLibraries} $out/lib/${libraryFile}
    addDriverRunpath $out/lib/${libraryFile}
  '';

  meta = {
    description = "Native C++ runtime of the PicoGK geometry kernel";
    homepage = "https://github.com/leap71/PicoGKRuntime";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
