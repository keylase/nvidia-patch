nv-driver-locator
=================

nv-driver-locator is a tool for internal usage, which purpose is to notify about new Nvidia driver releases. It's kernel supports and performs:

* Update retrieval from multiple sources (**channels** component).
* Notification through various ways (**notifiers** component).
* Driver info matching and aggregation via configurable set of attributes (**hasher** component).
* Persistence of collected data for keeping track on already seen drivers (**db** component).

## Requirements

* Python 3.4+
* `beautifulsoup4` package - required only when NvidiaDownloadsChannel is used. On recent Debian/Ubuntu you may install it like this: `apt-get install python3-bs4`. For other cases see [this](https://www.crummy.com/software/BeautifulSoup/bs4/doc/#installing-beautiful-soup).

## Overview

### Structure

All scripts may be used both as standalone application and importable module. For CLI synopsys invoke program with `--help` option.

* nv-driver-locator.py - main executable, intended to be run as cron job.
* mailer.py - module with email routines and minimalistic email client for test purposes.
* gfe\_get\_driver.py - GeForce Experience client library (and test util).
* get\_nvidia\_downloads.py - Nvidia downloads site parser (and test util).
* get\_vulkan\_downloads.py - Nvidia Developer downloads site parser (and test util). Used for Vulkan Beta Drivers.

### Operation

1. Cron job queries all configured channels.
2. Program aggregates responses by hashing their's values covered by `key_components`. `key_components` is a list of JSON paths (represented by list too) specified in config file.
3. Program queries DB if given hash has any match in database.
4. If no match found and we have new instance, then all notifiers are getting fired.
5. New record gets written into DB.

## Configuration example

See [nv-driver-locator.json.sample](nv-driver-locator.json.sample).

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
* `timeout` - allowed delay in seconds for each network operation. Default: `10.0`

#### NvidiaDownloadsChannel

Parses Nvidia downloads site.

Type: `nvidia_downloads`

Params:

* `os` - OS family, version and bitness. Allowed values: `Linux_32`, `Linux_64`, `Windows7_32`, `Windows7_64`, `Windows10_32`, `Windows10_64`, `WindowsServer2012R2_32`, `WindowsServer2012R2_64`, `WindowsServer2016`, `WindowsServer2019`. Default: `Linux_64`.
* `product` - product kind. Allowed values: `GeForce`, `GeForceMobile`, `Quadro`, `QuadroMobile`. Default: `GeForce`.
* `certlevel` - driver certification level. Allowed values: `All` - any certification level, `Beta` - beta drivers, `Certified` - WHQL certified in Windows case and Nvidia certified in Linux case, `ODE` - Optimal Driver for Enterprise (Quadro driver), `QNF` - Quadro New Feature (Quadro driver). Default: `All`.
* `driver_type` - driver type. Allowed values: `Standard`, `DCH`. At this moment DCH driver appears to exists only for some product families and only for Windows 10 x64. Default: `Standard`.
* `lang` - driver language. Allowed values: `English`. Default: `English`.
* `cuda_ver` - verson of CUDA Toolkit bundled with driver. Currently useless for covered product families. Default: `Nothing`.
* `timeout` - allowed delay in seconds for each network operation. Default: `10.0`

#### CudaToolkitDownloadsChannel

Parses CUDA Toolkit downloads archive and extracts kit name instead of driver name.

Type: `cuda_downloads`

Params:

* `timeout` - allowed delay in seconds for each network operation. Default: `10.0`

#### VulkanBetaDownloadsChannel

Parses Nvidia Developer downloads site for latest Vulkan Beta Drivers.

Type: `vulkan_beta`

Params:

* `timeout` - allowed delay in seconds for each network operation. Default: `10.0`

#### DebRepoChannel

Parses Packages or Packages.gz file of deb package repository and extracts versions information.

Type: `deb_packages`

Params:

* `url` - Location of `Packages` or `Packages.gz` file.
* `pkg_pattern` - regexp which defines package name pattern.
* `driver_name` - value returned as `DriverAttributes.Name` for proper aggregation by Hasher. Default: `"Linux x64 (AMD64/EM64T) Display Driver"`
* `timeout` - allowed delay in seconds for each network operation. Default: `10.0`

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
