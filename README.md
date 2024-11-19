# NixOS Flake for Caddy with Modules 

Caddy's third-party plugins are installed by adding them as import in
`cmd/caddy/main.go` and compiling caddy. This can be done either using the
`xcaddy` utility as described [here](https://caddyserver.com/docs/build) in the
official docs or by creating a `main.go` file with the import and compiling with
`go build` manually. This process is outlined in the upstream
[here](https://github.com/caddyserver/caddy/blob/82c356f2548ca62b75f76104bef44915482e8fd9/cmd/caddy/main.go#L21-L25).
The `xcaddy` utility is not suited for deployment on NixOS where a sandboxed,
reproducible build is required.

This flake compiles caddy from a custom `main.go` file as outlined above.
Currently adding the popular [caddy-security](https://authp.github.io/) as an
example. The `caddy` package of this flake's  output will be caddy with that
plugin baked in.

To modify/add plugins:

1. Edit `caddy-src/main.go` as per the upstream docs
2. Run `go mod tidy`
3. If necessary, update the hash in `flake.nix`
4. Run `nix build`

You should get a result with the compiled caddy. To verify that the plugins
where correctly added use:

```
./result/bin/caddy list-modules  
```

# Install Guide

Add caddy-with-modules to you flake inputs and set `specialArgs = inputs;` to make it available to your configs input

```nix
# flake.nix
{
  # ...
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    caddy-with-modules = {
      url = "github:escherlies/nixos-caddy-with-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  # ...

  outputs = 
    {
      nixosConfigurations = {
          some-config = nixpkgs.lib.nixosSystem {
            # Pass all inputs as specialArgs
            specialArgs = inputs;
          };
      };
    };
}
```

Add caddy-with-modules to your input of the config, add the package and add `AmbientCapabilities`.

```nix
{
  lib,
  pkgs,
  config,
  caddy-with-modules,
  ...
}:{
  # ...
  config = {
    # ...

    systemd.services.caddy.serviceConfig = {
      # https://serverfault.com/a/899964
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    };

    services.caddy = {
      enable = true;
      package = caddy-with-modules.packages.x86_64-linux.caddy;

      virtualHosts."${config.virtualHost}" = {
        extraConfig = builtins.readFile ./Caddyfile;
      };
    };
  };
}
```



You may want to add configuration options, as outlined for example here : https://github.com/pinpox/nixos/blob/f854c869cc6021ab60c4fd221a6aed23cf3469ab/modules/caddy-security/default.nix

# Credits

Thanks to [@pinpox](https://github.com/pinpox/) and his mad crazy [nixos repository](https://github.com/pinpox/nixos) from where I copy pasta the caddy with modules config 🍝❤️


