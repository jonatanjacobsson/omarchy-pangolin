# Pangolin for Omarchy

Show [Pangolin](https://github.com/fosrl/pangolin) VPN status in the Omarchy bar: connect, disconnect, and browse sites.

This is an [Omarchy shell plugin](https://omarchy.org/manual/shell-plugins/). Plugins run unsandboxed inside `omarchy-shell` with your user account. Read the files before you enable it.

## Install

Install the Pangolin CLI first and log in (`pangolin login`), then:

```sh
omarchy plugin add https://github.com/jonatanjacobsson/omarchy-pangolin.git --enable
```

Put the widget on the bar if it is not already there:

```sh
omarchy bar add tinkin.pangolin --section right
```

## Use

| Input | Action |
| --- | --- |
| Left click | Open the sites panel |
| Right click | Connect or disconnect |
| Middle click | Refresh status |
| `T` in the panel | Connect or disconnect |
| `R` in the panel | Refresh status |

The bar shows only the [Pangolin mark](https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pangolin.svg): filled orange when connected, greyed out when not.

Connecting from the bar needs admin rights to create the tunnel device. The widget calls `pkexec` the same way Omarchy’s Tailscale widget does, so the usual password or fingerprint dialog can authorize a short-lived `pangolin-olm` systemd unit.

## Requirements

- `pangolin` on `PATH` (or `~/.local/bin/pangolin`)
- An account that can already `pangolin up` from a terminal

## Remove

```sh
omarchy plugin remove tinkin.pangolin
```

That does not log out of Pangolin or stop a tunnel that is already up.

## License

MIT. The Pangolin name and mark belong to [Fossorial](https://github.com/fosrl). The bar SVG is the [Homarr dashboard icon](https://github.com/homarr-labs/dashboard-icons).
