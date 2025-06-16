# tac_plus container 
[![create and publish container](https://github.com/sulrich/docker-tacplus/actions/workflows/create-container.yml/badge.svg)](https://github.com/sulrich/docker-tacplus/actions/workflows/create-container.yml)

minimal build and implementation of the tac_plus server from [marc
huber](https://www.pro-bono-publico.de/projects/).
([github](https://github.com/MarcJHuber/event-driven-servers/))

this uses a container for bulding the binaries and then copies these to a target
container with the various additional elements that come along for the ride.

## notable files

the embedded `tac_plus.cfg` has the barest of configuration elements but does
specify some log files to be placed within `/var/log/tac_plus`. the
`docker-entry.sh` script within the container will generate this directory for
you.  i find it useful to overlay `/var/log` with a volume mount of my
specification so i can see these logs.  

additionally, i stick my personal `tac_plus.cfg` file in a handy location for
containerlab, etc, and override this too with a binding mount. attempting to
redirect tac_plus logs to STDOUT to facilitate grokking them via `docker logs -f
<container_name>` has been a rabbit hole i haven't really gone down.  it looks
like tac_plus `seek()`s or pays attention to the logfile location if you're not
using syslog.

this is not meant for anything remotely approximating a production environment
and has an embedded tacacs key (`sw33t_key`) and provides the default
credentials of ... spoiler alert! username: `admin` password: `admin`.

### sample binding mounts

**vanilla docker**

```shell
  -v ${HOME}/clab/etc/tac_plus:/etc/tac_plus
  -v ${HOME}/clab/var/tac_plus:/var/log/tac_plus
```

**containerlab sample entry**

the following binds the container to the management network in containerlab
which is probably what you want anyway.

```yaml
    tacplus:
      kind: linux
      image: ghcr.io/sulrich/docker-tacplus:main
      binds:
        - ${HOME}/clab/etc/tac_plus:/etc/tac_plus
        - ${HOME}/clab/var/tac_plus:/var/log/tac_plus
      mgmt_ipv4: 172.20.20.xx

  links:
    # this binds the container to the management network
    - endpoints: ["tacplus:eth1", "mgmt-net:tacplus-eth1"]
```

## references

- [tac_plus documentation](https://www.pro-bono-publico.de/projects/unpacked/doc/tac_plus.pdf)
