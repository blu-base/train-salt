# train-salt - Train Plugin for connecting to remote systems via the Salt API

> [!CAUTION]
> Consider this project as experimental


This plugin allows applications, such as [inspec](https://github.com/inspec/inspec)
and [cinc-auditor](https://cinc.sh/start/auditor/),
that rely on Train to communicate via Salt's API service.
[Salt](https://saltproject.io/) is an agent-based configuration management
system. Instead of using ssh, this plugin sends requests via the
salt api to remote systems. 

## Quickstart

### Install `train-salt` for `inspec`

You will need InSpec v2.3 or later.

If you just want to use this (not learn how to write a plugin), you can so by simply running:

```
$ inspec plugin install train-salt
```

or, if you use `cinc-auditor`:

```
$ cinc-auditor plugin install train-salt
```

### Set up the `salt-api` service

You'll need to setup a salt-api service, such as salt's [cherrypy
netapi](https://docs.saltproject.io/en/latest/ref/netapi/all/salt.netapi.rest_cherrypy.html).
Please refer to the respective documentation for Salt:
[netapi](https://docs.saltproject.io/en/latest/ref/netapi/all/index.html). The
configuration of the `salt-master` service and `salt-api` service are tightly
coupled.

Don't forget to enable `netapi` clients in the salt-master configuration.
`train-salt` uses the `local` client and mostly the `cmd.run` execution module.
Ensure your master's configuration contains:

```
netapi_enable_clients:
  - local
```


Now setup an account to be used by `train-salt`. Please be referred to the
[external authentication
system](https://docs.saltproject.io/en/latest/topics/eauth/index.html)
documentation. If you create an account on the same system as the salt-api
service, you can use the linux `pam` module. Your external authentication
configuration for the `salt-master` could look like:

```
external_auth:
  pam:
    inspec-api-user:
      - '*':
         - test.*
         - cmd.run
```

Don't forget to restart the `salt-master` and `salt-api` service after changing
its configuration.

### Execute commands via the salt backend

Prepare a configuration file containing the address of the `salt-api`
service and the credentials to be used with the Salt API. E.g.:

train-salt-config.json
```json
{
  "url": "https://salt-master:8000",
  "username": "inspec-api-user",
  "password": "mysecret",
  "eauth": "pam"
}
```

You can then run:

```
$ inspec detect -t salt://minion_id --config train-salt-config.json
== Platform Details

Name:      ubuntu
Families:  debian, linux, unix, os
Release:   22.04
Arch:      x86_64

$ inspec shell -t salt://minion_id --config train-salt-config.json -c 'command("hostname").stdout'
minion_id
```

## Relationship between InSpec and Train

Train itself has no CLI, nor a sophisticated test harness. InSpec does have
such facilities, so installing Train plugins will require an InSpec
installation. You do not need to use or understand InSpec.

Train plugins may be developed without an InSpec installation.

## How to build

Install the required gems. Jump in this project's root directory, and run:

```
$ bundle install
```

Then build the gem using the gemspec file.
```
gem build train-salt.gemspec
```
