LINK := $(readlink result)

build:
	@nix build

run:
	@nix run

clean:
	@rm result
	@nix store delete $(LINK)
