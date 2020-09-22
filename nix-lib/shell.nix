{ lib
, writeShellScript
}:

{
  # Expansion / improvement of 'setuptoolsShellHook' at
  # 'pkgs/development/interpreters/python/hooks/setuptools-build-hook.sh'.
  #
  # Usually, from your nix-shell:
  # pyProjectDir = builtins.toString ./.;
  # pyPkg: A python package based on `buildPythonPackage`.
  #
  runSetuptoolsShellHook = pyProjectDir: pyPkg: ''
    py_project_dir="${pyProjectDir}"
    if ! test -e "$py_project_dir/setup.py"; then
      1>&2 echo "WARNING: Cannot find 'setup.py' for current project."
    else
      tmp_path=$(mktemp -d)
      export "PATH=$tmp_path/bin:$PATH"
      export "PYTHONPATH=$tmp_path/${pyPkg.pythonModule.sitePackages}:$PYTHONPATH"
      mkdir -p "$tmp_path/${pyPkg.pythonModule.sitePackages}"
      python -m pip install -e "$py_project_dir" --prefix "$tmp_path" >&2

      if [[ -d "$tmp_path/bin" ]]; then
        while read -r f; do
          if cat "$f" | head -n1 | grep -E '^#!/' | grep -q 'python'; then
            # Hack to fool 'patchShebangs' into thinking that the shebang
            # interpreter is not part of the nix store so that it is
            # patched again.
            NIX_STORE="/not/nix/store" patchShebangs "$f"
          fi
        done < <(find "$tmp_path/bin" -mindepth 1 -maxdepth 1 -type f -executable)
      fi
    fi
  '';

  # A shell hook lib.
  # To be sourced as follow from your shell hook:
  # `source ${nsfPy.shell.shellHookLib}`.
  shellHookLib = writeShellScript "nsf-py-shell-hook-lib.sh" ''
    # TODO: Make this more concise.
    # Workaround the vscode debugger issue observed when using the bash colon
    # trick.
    nsf_py_prefix_path() {
      local varname="''${1?}"
      local -n old_value="''${1?}"
      local prefixed_value="''${2?}"
      if [[ -z "''${old_value}" ]]; then
        export "''${varname}=$prefixed_value"
      else
        export "''${varname}=$prefixed_value:''${old_value}"
      fi
    }

    nsf_py_set_interpreter_env() {
      python_interpreter="''${1?}"
      if ! [[ -e "$python_interpreter" ]]; then
        1>&2 echo "ERROR: ''${FUNCNAME[0]}: Cannot find expected " \
          "'$python_interpreter' python interpreter path."
        exit 1
      fi
      if [[ -d "$python_interpreter" ]] || ! [[ -x "$python_interpreter" ]]; then
        1>&2 echo "ERROR: ''${FUNCNAME[0]}: Specified python interpreter path " \
          "'$python_interpreter' does not refer to a executable program."
        exit 1
      fi

      export "PYTHON_INTERPRETER=$python_interpreter"
    }

    nsf_py_set_interpreter_env_from_path() {
      local python_interpreter
      python_interpreter="$(which python)"
      nsf_py_set_interpreter_env "$python_interpreter"
    }

    nsf_py_set_interpreter_env_from_nix_store_path() {
      local python_interpreter_nix_store_path="''${1?}"
      local python_interpreter="$python_interpreter_nix_store_path/bin/python"
      nsf_py_set_interpreter_env "$python_interpreter"
    }

    nsf_py_add_local_pkg_src_if_present() {
      local pkg_src_dir="''${1?}"
      if [[ -e "$pkg_src_dir" ]]; then
        nsf_py_prefix_path "PYTHONPATH" "$pkg_src_dir"
        nsf_py_prefix_path "MYPYPATH" "$pkg_src_dir"
      fi
    }

    nsf_py_mypy_5701_workaround() {
      # Workaround for 'mypy/issues/5701'
      local pyton_nix_store_path="''${1?}"
      local pythonV
      pythonV="$(echo "$pyton_nix_store_path" \
        | awk -F/ '{ print $4 }' \
        | awk -F- '{ print $3}' \
        | awk -F. '{ printf "%s.%s", $1, $2 }')"

      local pythonSitePkgs="''${pyton_nix_store_path}/lib/python''${pythonV}/site-packages"

      if ! [[ -e "$pythonSitePkgs" ]]; then
        1>&2 echo "ERROR: ''${FUNCNAME[0]}: Cannot find expected " \
          "'$pythonSitePkgs' python site package path."
        exit 1
      fi

      nsf_py_prefix_path "MYPYPATH" "''${pyton_nix_store_path}/lib/python''${pythonV}/site-packages"
    }

    nsf_py_mypy_5701_workaround_from_path() {
      local pyton_nix_store_path
      pyton_nix_store_path="$(which python | xargs dirname | xargs dirname)"
      nsf_py_mypy_5701_workaround "$pyton_nix_store_path"
    }
  '';
}
