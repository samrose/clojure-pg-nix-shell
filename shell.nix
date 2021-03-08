{ pkgs ? import ./nixpkgs.nix { } }:
with pkgs;
let
  inherit (perlPackages) vidir;
  neovim-with-config = neovim.override {
    configure = {
      customRC = ''
        set title
        set nu
        let g:rainbow_active = 1
      '';
      packages.package.start = with vimPlugins; [
        fzf
        rainbow
        vim-clojure-highlight
        vim-clojure-static
        vim-fireplace
        vim-nix
        vim-parinfer
      ];
    };

    viAlias = true;

  };
  postgresConf =
    writeText "postgresql.conf"
      ''
        # Add Custom Settings
        log_min_messages = warning
        log_min_error_statement = error
        log_min_duration_statement = 100  # ms
        log_connections = on
        log_disconnections = on
        log_duration = on
        #log_line_prefix = '[] '
        log_timezone = 'UTC'
        log_statement = 'all'
        log_directory = 'pg_log'
        log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
        logging_collector = on
        log_min_error_statement = error
      '';
in

mkShell {


  buildInputs = [
    clojure
    geckodriver
    git
    joker
    leiningen
    nixpkgs-fmt
    neovim-with-config
    postgresql 
    python3
  ];
  shellHook = ''
    set -a 
    source env.sh
    set +a
    export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
    #export HART_FE_CDN_URL=https://cdn.harttools.torquestaging.com
    export PGDATA=$PWD/postgres_data
    export PGHOST=$PWD/postgres #DO NOT SETTHIS VARIABLE!!!!!!!!. phoenix gets confused 
    export LOG_PATH=$PWD/postgres/LOG
    export PGDATABASE=postgres
    export DATABASE_URL="postgresql:///postgres?host=$PGHOST"
    if [ ! -d $PWD/postgres ]; then
      mkdir -p $PWD/postgres
    fi
    if [ ! -d $PGDATA ]; then
      echo 'Initializing postgresql database...'
      initdb $PGDATA --auth=trust >/dev/null
      cat "$postgresConf" >> $PGDATA/postgresql.conf
    fi
    pg_ctl start -l $LOG_PATH -o "-c listen_addresses='*' -c unix_socket_directories=$PWD/postgres -c unix_socket_permissions=0700"
    '';

}

