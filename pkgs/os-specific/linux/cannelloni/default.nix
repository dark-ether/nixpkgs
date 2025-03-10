{ stdenv, lib, fetchFromGitHub, cmake, lksctp-tools, sctpSupport ? true }:
stdenv.mkDerivation (finalAttrs: {
  pname = "cannelloni";
  version = "1.1.0";
  src = fetchFromGitHub {
    owner = "mguentner";
    repo = "cannelloni";
    rev = "v${finalAttrs.version}";
    hash = "sha256-pAXHo9NCXMFKYcIJogytBiPkQE0nK6chU5TKiDNCKA8=";
  };
  buildInputs = [ cmake ] ++ lib.optionals sctpSupport [ lksctp-tools ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DSCTP_SUPPORT=${lib.boolToString sctpSupport}"
  ];

  meta = with lib; {
    description = "A SocketCAN over Ethernet tunnel";
    homepage = "https://github.com/mguentner/cannelloni";
    platforms = platforms.linux;
    license = licenses.gpl2Only;
    maintainers = [ maintainers.samw ];
  };
})
