{
  lib,
  pkgs,
  config,
  ...
}:
let
  key.public = "age1a3t3jnvayl40n4l5c7zmuglsw07u3m2p52ckr67tlj76w6t464gsufuveg";
  key.private = ./passpass_key.age;
  remote = "git@github.com:Axyuwu/passpass-store.git";
  local = lib.escapeShellArg "${config.home.homeDirectory}/.local/share/passpass";
  git = "${pkgs.git}/bin/git";
  age = "${pkgs.age}/bin/age";
  passpass-sync = pkgs.writeShellScriptBin "passpass-sync" ''
    set -e -u -o pipefail

    cd ${local}/store

    ${git} push origin main
    ${git} pull origin main
  '';
  passpass-encrypt = pkgs.writeShellScriptBin "passpass-encrypt" ''
    set -e -u -o pipefail

    TMP=$(mktemp -d)

    if [[ $# != 1 ]]; then
      echo "please provide exacly one argument, it being the string used to look up the secret"
      exit 1
    fi

    echo -n "$1" | ${age} -r ${key.public} -o $TMP/search 

    ${age} -r ${key.public} -o $TMP/value

    HASH="$(cat $TMP/* | sha1sum -b | head -c 40)"

    mv $TMP ${local}/store/$HASH

    cd ${local}/store
    ${git} add .
    ${git} commit -am "added secret"
    ${git} push origin main
  '';
  passpass-gen = pkgs.writeShellScriptBin "passpass-gen" ''
    read -r -p 'Resource: ' RES
    if [[ -z "$RES" ]]; then
      echo "A password must be attached to a resource!"
      exit 1
    fi
    read -r -p 'EMail: ' EMAIL
    read -r -p 'Username: ' USERNAME

    PASSWORD=$(tr -cd [:graph:] < /dev/random | head -c24)

    SEARCH=$RES
    if [[ -n $EMAIL ]]; then SEARCH="$SEARCH/$EMAIL"; fi
    if [[ -n $USERNAME ]]; then SEARCH="$SEARCH/$USERNAME"; fi

    (
      echo "email: $EMAIL"
      echo "username: $USERNAME"
      echo "password: $PASSWORD"
    ) | ${passpass-encrypt}/bin/passpass-encrypt "$SEARCH" &

    ${pkgs.wl-clipboard}/bin/wl-copy -o -f "$PASSWORD"

    wait
  '';
  passpass-auth = pkgs.writeShellScriptBin "passpass-auth" ''
    set -e -u -o pipefail

    if [[ ! -f /run/user/$UID/passpass/decrypted.key ]]; then
      TMP=/run/user/$UID/passpass/decrypted.key.tmp
      touch $TMP
      chmod 600 $TMP

      ${age} -d -o $TMP /run/user/$UID/passpass/encrypted.key

      mv -f $TMP /run/user/$UID/passpass/decrypted.key
    fi
  '';
  passpass-unauth = pkgs.writeShellScriptBin "passpass-unauth" ''
    set -e -u -o pipefail

    rm /run/user/$UID/passpass/decrypted.key
  '';
  passpass-decrypt = pkgs.writeShellScriptBin "passpass-decrypt" ''
    set -e -u -o pipefail

    ${passpass-auth}/bin/passpass-auth

    KEY=/run/user/$UID/passpass/decrypted.key

    declare -A SECRETS
    for DIR in ${local}/store/*/; do
      SECRETS["$(${age} -d -i $KEY $DIR/search)"]=$DIR/value
    done

    FILE_SEARCH="$(for SEARCH in "''${!SECRETS[@]}"; do
      echo $SEARCH
    done \
    | ${pkgs.fzf}/bin/fzf)"

    ${age} -d -i $KEY "''${SECRETS[$FILE_SEARCH]}"
  '';
  passpass-remove = pkgs.writeShellScriptBin "passpass-remove" ''
    set -e -u -o pipefail

    ${passpass-auth}/bin/passpass-auth

    KEY=/run/user/$UID/passpass/decrypted.key

    declare -A SECRETS
    for DIR in ${local}/store/*/; do
      SECRETS["$(${age} -d -i $KEY $DIR/search)"]=$DIR
    done

    FILE_SEARCH="$(for SEARCH in "''${!SECRETS[@]}"; do
      echo $SEARCH
    done \
    | ${pkgs.fzf}/bin/fzf)"

    DIR="''${SECRETS[$FILE_SEARCH]}"

    rm $DIR/search $DIR/value
    rmdir $DIR

    cd ${local}/store
    ${git} add .
    ${git} commit -am "removed secret"
    ${git} push origin main
  '';
  passpass-setup = lib.getExe (
    pkgs.writeShellApplication {
      name = "passpass-setup";
      runtimeInputs = with pkgs; [
        coreutils-full
        diffutils
      ];
      text = ''
        set -e -u -o pipefail

        if [[ -d /run/user/$UID/passpass ]]; then
          chmod 700 /run/user/$UID/passpass
        else
          mkdir -m 700 /run/user/$UID/passpass
        fi
          
        if ! cmp -s /run/user/$UID/passpass/encrypted.key ${key.private}; then
          ln ${key.private} /run/user/$UID/passpass/encrypted.key
          rm -f /run/user/$UID/passpass/decrypted.key
        fi

        mkdir -p ${local}/store

        cd ${local}/store

        ${git} init -b main

        ${git} remote add origin ${remote} \
        || ${git} remote set-url origin ${remote}
      '';
    }
  );
in
{
  config = {
    home.packages = [
      passpass-sync
      passpass-encrypt
      passpass-gen
      passpass-auth
      passpass-unauth
      passpass-decrypt
      passpass-remove
    ];
    systemd.user.services.passpass = {
      Unit.Description = "passpass activation";
      Service = {
        Type = "oneshot";
        ExecStart = passpass-setup;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
