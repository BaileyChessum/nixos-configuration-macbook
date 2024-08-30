# https://github.com/NixOS/nixpkgs/issues/107233
self: super: 
 
{
  zoom-us = super.zoom-us.overrideAttrs (attrs: {
    nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ [
      self.bbe
    ];               
    postFixup = ''
      cp $out/opt/zoom/zoom .
      bbe -e 's/\0manjaro\0/\0nixos\0\0\0/' < zoom > $out/opt/zoom/zoom
    '' + (attrs.postFixup or "");# + ''
    #  wrapProgram $out/bin/zoom --unset XDG_SESSION_TYPE
    #  wrapProgram $out/bin/zoom-us --unset XDG_SESSION_TYPE
    #'';
  });
}