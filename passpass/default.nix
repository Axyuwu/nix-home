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
  salt-bytes = 32;
  common-funcs = ''
    set -e -u -o pipefail

    secure_encrypt () {
      cat \
        <(
        head -c${builtins.toString salt-bytes}</dev/urandom \
        | ${pkgs.xxd}/bin/xxd -p \
        | tr -d '\n'
        printf '\n'
        ) \
        - \
        | ${age} -r ${key.public}
    }

    secure_decrypt () {
      KEY=/run/user/$UID/passpass/decrypted.key
      
      ${age} -d -i "$KEY" | tail -c+${builtins.toString (salt-bytes * 2 + 2)}
    }

    # Sets the variable $SECRETS to the store search values and its value path
    read_store () {
      declare -g -A SECRETS
      for DIR in ${local}/store/*/; do
        if [[ ! -e $DIR ]]; then
          continue
        fi
        local INDEX=$(cat $DIR/index | secure_decrypt)
        if [[ -n ''${SECRETS[$INDEX]+x} ]]; then
          echo "Dupplicate secret for index:"
          echo "$INDEX"
          echo "Paths:"
          echo "''${SECRETS[$INDEX]}"
          echo "$DIR"
          exit 1
        fi
        SECRETS[$INDEX]=$DIR
      done
    }
  '';
  passpass-encrypt = pkgs.writeShellScriptBin "passpass-encrypt" ''
    ${common-funcs}

    ${passpass-auth}/bin/passpass-auth

    TMP=$(mktemp -d)

    if [[ $# != 1 ]]; then
      echo "please provide exacly one argument, it being the string used to look up the secret"
      exit 1
    fi

    INDEX="$1"

    read_store

    if [[ -n "''${SECRETS[$INDEX]:-}" ]]; then
      echo "Secret already exists for resource:"
      echo "  $INDEX"
      echo "Path:"
      echo "  ''${SECRETS[$INDEX]}"
      echo "Aborting"
      exit 1
    fi

    echo -n "$INDEX" | secure_encrypt > $TMP/index

    secure_encrypt > $TMP/value

    STORE_PATH=$(${pkgs.xxd}/bin/xxd -p <(head -c20</dev/urandom))

    mv $TMP ${local}/store/$STORE_PATH

    cd ${local}/store
    ${git} add .
    ${git} commit -am "added secret"
    ${git} push ${remote}
  '';
  passpass-decrypt = pkgs.writeShellScriptBin "passpass-decrypt" ''
    ${common-funcs}

    ${passpass-auth}/bin/passpass-auth

    read_store

    if [[ ''${#SECRETS[@]} == 0 ]]; then
      echo "No secrets have been set!"
      exit 1
    fi

    INDEX="$(for INDEX in "''${!SECRETS[@]}"; do
      echo "$INDEX"
    done \
    | ${pkgs.fzf}/bin/fzf)"

    cat "''${SECRETS[$INDEX]}"/value | secure_decrypt
  '';
  passpass-schemas =
    builtins.mapAttrs
      (
        _name: schema:
        builtins.map
          (
            field:
            {
              required = false;
              search = true;
              value = true;
            }
            // field
            // (
              if builtins.hasAttr "generator" field then
                {
                  required = true;
                  search = false;
                  value = true;
                }
              else
                { }
            )
          )
          (
            lib.lists.singleton {
              display = "Resource";
              required = true;
              search = true;
              value = false;
            }
            ++ schema
          )
      )
      {
        account = [
          {
            name = "email";
            display = "EMail";
          }
          {
            name = "username";
            display = "Username";
          }
          {
            name = "password";
            display = "Password";
            generator = "head -c 24 <(tr -cd [:graph:] < /dev/random)";
          }
        ];
      };
  map-gen-apply = (
    fnogen: fgen: field:
    if builtins.hasAttr "generator" field then fgen field else fnogen field
  );
  schema-to-gen =
    name: schema:
    pkgs.writeShellScript "passpass-gen-${name}" ''
      set -e -u -o pipefail

      SECRET=${lib.escapeShellArg "type: ${name}"}
      SEARCH="";

      ${lib.strings.concatMapStringsSep "\n" (map-gen-apply
        (field: ''
          read -r -p \
            ${
              lib.escapeShellArg (
                lib.concatStrings [
                  field.display
                  (lib.strings.optionalString (!(field.required)) " (Optional)")
                  ": "
                ]
              )
            } \
            VALUE

          ${lib.strings.optionalString field.required ''
            if [[ -z "$VALUE" ]]; then
              echo ${lib.escapeShellArg field.display} required
              exit 1
            fi
          ''}

          ${lib.strings.optionalString field.value ''
            SECRET+=${lib.escapeShellArg "\n${field.name}: "} 
            SECRET+="$VALUE"
          ''}
          ${lib.strings.optionalString field.search ''
            if [[ -n "$VALUE" ]]; then
              if [[ "$SEARCH" != "" ]]; then
                SEARCH+=" : "
              fi
              SEARCH+="$VALUE"
            fi
          ''}
        '')
        (field: ''
          echo "$SECRET"
          echo "$SEARCH"
          VALUE=$(${field.generator})
          echo "test"
          SECRET+=${lib.escapeShellArg "\n${field.name}: "} 
          SECRET+="$VALUE"
          echo "${field.display} copied to clipboard 1/2"
          ${pkgs.wl-clipboard}/bin/wl-copy -o -f "$VALUE"
          echo "${field.display} copied to clipboard 2/2"
          ${pkgs.wl-clipboard}/bin/wl-copy -o -f "$VALUE"
        '')
      ) schema}

      echo -n "$SECRET" \
        | ${passpass-encrypt}/bin/passpass-encrypt "$SEARCH"
    '';
  passpass-gen =
    let
      schemas = lib.attrsets.mapAttrsToList (name: schema: {
        inherit name schema;
      }) passpass-schemas;
      schemas-dir = pkgs.runCommand "passpass-schema-dir" { } ''
        mkdir $out
        ${lib.strings.concatMapStringsSep "\n" (
          schema: "ln -s ${schema-to-gen schema.name schema.schema} $out/${lib.escapeShellArg schema.name}"
        ) schemas}
      '';
    in
    pkgs.writeShellScriptBin "passpass-gen" ''
      SCHEMA=$((
      ${lib.strings.concatMapStringsSep "\n" (schema: "  echo ${lib.escapeShellArg schema.name}") schemas}
      ) | ${pkgs.fzf}/bin/fzf)

      ${schemas-dir}/$SCHEMA
    '';
  schema-get =
    name: schema:
    pkgs.writeShellScript "passpass-get-${name}" ''
      set -e -u -o pipefail

      readarray -t SECRETS
      IDX=0

      ${lib.strings.concatMapStringsSep "\n" (schema: ''
        [[ ''${SECRETS[IDX]} == ${lib.escapeShellArg "${schema.name}: "}* ]] \
          || (
            echo  "Invalid line in secret, expected line starting with header:"
            echo ${lib.escapeShellArg "  ${schema.name}: "}
            echo "Current line: $IDX"
            exit 1
          )

          SECRET="''${SECRETS[IDX]#${lib.escapeShellArg "${schema.name}: "}}"
          if [[ -n "$SECRET" ]]; then
            echo ${lib.escapeShellArg "${schema.display} copied to clipboard"}
            ${pkgs.wl-clipboard}/bin/wl-copy -o -f "$SECRET"
          fi

          ((IDX+=1))
      '') (builtins.filter (schema: schema.value) schema)}
    '';
  passpass-get = pkgs.writeShellScriptBin "passpass-get" ''
    set -e -u -o pipefail

    SECRET=$(${passpass-decrypt}/bin/passpass-decrypt)

    TYPE=$(echo -n "$SECRET" | head -n 1)

    [[ $TYPE == "type: "* ]] \
      || (
        echo "Secret does not have a type header, so no schema could be found matching"
        exit 1
      )

    case "''${TYPE#"type: "}" in
      ${lib.strings.concatStringsSep "\n" (
        lib.attrsets.mapAttrsToList (name: schema: ''
          ${lib.escapeShellArg name})
            echo -n "$SECRET" | tail -n +2 | ${schema-get name schema}
          ;;
        '') passpass-schemas
      )}
    *)
      echo "Unrecognized secret schema type: ''${TYPE#"type: "}"
      exit 1
      ;;
    esac
  '';
  passpass-remove = pkgs.writeShellScriptBin "passpass-remove" ''
    set -e -u -o pipefail

    ${common-funcs}

    ${passpass-auth}/bin/passpass-auth

    read_store

    FILE_INDEX="$(for INDEX in "''${!SECRETS[@]}"; do
      echo $INDEX
    done \
    | ${pkgs.fzf}/bin/fzf)"

    DIR="''${SECRETS[$FILE_INDEX]}"

    rm $DIR/index $DIR/value
    rmdir $DIR

    cd ${local}/store
    ${git} add .
    ${git} commit -am "removed secret"
    ${git} push ${remote}
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
          ln -s ${key.private} /run/user/$UID/passpass/encrypted.key
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
  passpass-sync = pkgs.writeShellApplication {
    name = "passpass-sync";
    runtimeInputs = with pkgs; [
      openssh
    ];
    text = ''
      set -e -u -o pipefail

      cd ${local}/store

      ${git} pull ${remote}
      ${git} push ${remote}
    '';
  };
in
{
  config = {
    home.packages = [
      passpass-auth
      passpass-unauth
      passpass-encrypt
      passpass-decrypt
      passpass-gen
      passpass-get
      passpass-remove
      passpass-sync
    ];
    systemd.user.services.passpass = {
      Unit.Description = "passpass activation";
      Service = {
        Type = "oneshot";
        ExecStart = passpass-setup;
      };
      Install.WantedBy = [ "default.target" ];
    };
    systemd.user.services.passpass-sync = {
      Unit.Description = "passpass sync";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe passpass-sync;
      };
      Install.WantedBy = [ "default.target" ];
      Install.After = [ "passpass.service" ];
    };
    systemd.user.timers = {
      passpass-sync = {
        Unit.Description = "passpass sync with remote";
        Timer = {
          Unit = "passpass-sync";
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
