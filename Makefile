MKF_CWD := $(shell pwd)

.PHONY: all clean release

all: release

clean:
	rm -f ./result*

release:
	nix eval --show-trace --raw \
	  '(builtins.toString (builtins.isAttrs ((import ./release.nix {}).nix-lib)))'
	nix eval --show-trace --raw \
	  '(builtins.toString (builtins.isAttrs ((import ./release.nix {}).nix-lib.nsfpy)))'
	nix eval --show-trace --raw \
	  '(builtins.toString (builtins.isAttrs ((import ./release.nix {}).nix-lib.nsfpy.shell)))'
