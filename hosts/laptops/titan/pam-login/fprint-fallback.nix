{ pkgs, ... }:
# fprint+yubikey  >  fprint-only  (no password)
# Fprint is required; YubiKey adds MFA but is optional.
{
  security.pam.services.login = {
    fprintAuth = false;
    u2fAuth = false;
    rules.auth = {
      fprint_primary = {
        order = 10200;
        control = "[success=ok default=die]"; # fail → immediate deny, no password
        modulePath = "${pkgs.fprintd}/lib/security/pam_fprintd.so";
      };
      u2f_mfa = {
        order = 10300;
        control = "[success=done default=ignore]"; # YubiKey touch → MFA done
        modulePath = "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
        args = [ "cue" ];
      };
      fprint_permit = {
        order = 10400;
        control = "[success=done default=bad]"; # fprint ok, no YubiKey → accept
        modulePath = "${pkgs.linux-pam}/lib/security/pam_permit.so";
      };
    };
  };
}
