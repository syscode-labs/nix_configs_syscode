{ pkgs, ... }:
# fprint+yubikey only — both required, no fallback
{
  security.pam.services.login = {
    fprintAuth = false;
    u2fAuth = false;
    rules.auth = {
      fprint_primary = {
        order = 10200;
        control = "[success=ok default=die]"; # fail → immediate deny
        modulePath = "${pkgs.fprintd}/lib/security/pam_fprintd.so";
      };
      u2f_mfa = {
        order = 10300;
        control = "[success=done default=die]"; # fail → immediate deny
        modulePath = "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
        args = [ "cue" ];
      };
    };
  };
}
