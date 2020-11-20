[![Sensu Bonsai Asset](https://img.shields.io/badge/Bonsai-Download%20Me-brightgreen.svg?colorB=89C967&logo=sensu)](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-vsphere)
[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-skel.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-skel)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-skel.svg)](http://badge.fury.io/rb/sensu-plugins-skel)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-skel/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-skel)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-skel/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-skel)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-skel.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-skel)


## Sensu Vsphere Plugin
- [Overview](#overview)
- [Usage examples](#usage-examples)
- [Configuration](#configuration)
  - [Sensu Go](#sensu-go)
    - [Asset definition](#asset-definition)
    - [Check definition](#check-definition)
  - [Sensu Core](#sensu-core)
    - [Check definition](#check-definition)
- [Functionality](#functionality)
- [Additional information](#additional-information)
- [Installation from source and contributing](#installation-from-source-and-contributing)

### Overview

This plugin provides native disk instrumentation for metrics collection.

The Sensu assets packaged from this repository are built against the Sensu ruby runtime environment. When using these assets as part of a Sensu Go resource (check, mutator or handler), make sure you include the corresponding Sensu ruby runtime asset in the list of assets needed by the resource.  The current ruby-runtime assets can be found [here](https://bonsai.sensu.io/assets/sensu/sensu-ruby-runtime) in the [Bonsai Asset Index](bonsai.sensu.io)

#### Files
 * bin/metrics-vsphere.rb

### Usage

#### Help
```
Usage: ./metrics-vsphere.rb (options)
    -l, --command_type COMMAND_TYPE  Specify command type (CPU, MEM, NET, IO, VMFS, RUNTIME, ...)
    -c COMPUTE_RESOURCE_NAME,        Compute resource name.
        --compute_resource
    -D DATA_CENTER_NAME,             Data center name.
        --data_center_name
        --find_resource NAME         Help to find resource and path to it
    -H, --host HOST                  ESX or ESXi hostname
    -h, --host_name HOST_NAME        Host name.
    -i, --insecure                   Use insecure connection
        --metric_format METRIC_FORMAT
    -p, --password PASSWORD          Password to use with the username.
    -r, --period PERIOD               Sampling Period in seconds. Basic historic intervals: 300, 1800, 7200 or 86400. See config for any changes.
    -S, --scheme SCHEME              Metric naming scheme, text to prepend to metric
    -u, --user USER                  Username to connect with
    -N, --name VM_NAME               Virtual machine name.
```

### Configuration
#### Sensu Go
##### Asset registration

Assets are the best way to make use of this plugin. If you're not using an asset, please consider doing so! If you're using sensuctl 5.13 or later, you can use the following command to add the asset:

`sensuctl asset add sensu-plugins/sensu-plugins-vsphere`

If you're using an earlier version of sensuctl, you can download the asset definition from [this project's Bonsai Asset Index page](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-vsphere).

## Installation
### Sensu Go

See the instructions above for [asset registration](#asset-registration)

### Sensu Core
Install and setup plugins on [Sensu Core](https://docs.sensu.io/sensu-core/latest/installation/installing-plugins/)


