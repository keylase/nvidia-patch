nv-driver-locator
=================

nv-driver-locator is a tool for internal usage, which purpose is to notify about new Nvidia driver releases. It's kernel supports and performs:

* Update retrieval from multiple sources (**channels** component).
* Notification through various ways (**notifiers** component).
* Driver info matching and aggregation via configurable set of attributes (**hasher** component).
* Persistence of collected data for keeping track on already seen drivers (**db** component).

## Requirements

* Python 3.4+

## Overview

### Structure

All scripts may be used both as standalone application and importable module. For CLI synopsys invoke program with `--help` option.

* nv-driver-locator.py - main executable, intended to be run as cron job.
* mailer.py - module with email routines and minimalistic email client for test purposes.
* gfe\_get\_driver.py - GeForce Experience client library (and test util).

### Operation

1. Cron job queries all configured channels.
2. Program aggregates responses by hashing their's values covered by `key_components`. `key_components` is a list of JSON paths (represented by list too) specified in config file.
3. Program queries DB if given hash has any match in database.
4. If no match found and we have new instance all notifiers getting fired.
5. New record gets written into DB.

## Configuration example

```json
{
    "db": {
        "type": "file",
        "params": {
            "workdir": "/var/lib/nv-driver-locator"
        }
    },
    "key_components": [
        [
            "DriverAttributes",
            "Version"
        ]
    ],
    "channels": [
        {
            "type": "gfe_client",
            "name": "desktop defaults",
            "params": {}
        },
        {
            "type": "gfe_client",
            "name": "desktop beta",
            "params": {
                "beta": true
            }
        },
        {
            "type": "gfe_client",
            "name": "mobile",
            "params": {
                "notebook": true
            }
        },
        {
            "type": "gfe_client",
            "name": "mobile beta",
            "params": {
                "notebook": true,
                "beta": true
            }
        }
    ],
    "notifiers": [
        {
            "type": "email",
            "name": "my email",
            "params": {
                "from_addr": "notify-bot@gmail.com",
                "to_addrs": [
                    "recepient1@domain1.tld",
                    "recepient2@domain2.tld"
                ],
                "host": "smtp.google.com",
                "use_starttls": true,
                "login": "notify-bot",
                "password": "MyGoodPass"
            }
        },
        {
            "type": "command",
            "name": "sample command",
            "params": {
                "timeout": 10.0,
                "cmdline": [
                    "cat",
                    "-"
                ]
            }
        }
    ]
}
```

## Components Reference

### DB

#### FileDB

Stores data in files.

Type: `file`

Params:

* `workdir` - files location

### Channels

#### GFEClientChannel

Queries latest driver for Windows, using GeForce Experience API.

Type: `gfe_client`

Params:

* `notebook` - seek for Mobile driver. Default: `false`
* `x86_64` - seek for 64bit driver. Default: `true`
* `os_version` - OS version. Default: `"10.0"`
* `os_build` - OS build. Default: `"17763"`
* `language` - language. Default: `1033` (English)
* `beta` - request Beta driver. Default: `false`
* `dch` - request DCH driver. Default: `false` (request Standard Driver)

### Notifiers

#### CommandNotifier

Runs external process and pipes JSON with info about new driver into it

Type: `command`

Params:

* `cmdline` - list of command line arguments (where first is executable name)
* `timeout` - allowed execution time in seconds. Default: `10.0`

#### EmailNotifier

Sends email with attached JSON file with driver info. Supports TLS, STARTTLS and authentication, so it can be used to send notification via mailbox provided by public services like gmail.

Type: `email`

Params:

* `from_addr` - originating address
* `to_addrs` - list of destination addresses
* `host` - SMTP host. Default: `localhost`
* `port` - SMTP port. Default: depends on chosen TLS/STARTTLS mode.
* `local_hostname` - hostname used in EHLO/HELO commands. Default: auto
* `use_ssl` - use SSL from beginning of connection. Default: `false`
* `use_starttls` - use STARTTLS. Default: `false`
* `login` - user login name. Default: `null` (do not use authentication)
* `password` - user password. Default: `null`
* `timeout` - allowed delay in seconds for each network operation. Default: `10.0`
