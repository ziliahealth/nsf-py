{ lib }:

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

      while read -r f; do
        if cat "$f" | head -n1 | grep -E '^#!/' | grep -q 'python'; then
          # Hack to fool 'patchShebangs' into thinking that the shebang
          # interpreter is not part of the nix store so that it is
          # patched again.
          NIX_STORE="/not/nix/store" patchShebangs "$f"
        fi
      done < <(find "$tmp_path/bin" -mindepth 1 -maxdepth 1 -type f -executable)
    fi
  '';
}
