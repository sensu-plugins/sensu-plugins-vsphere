# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed [here](https://github.com/sensu-plugins/community/blob/master/HOW_WE_CHANGELOG.md)

## Unreleased
### Added
- Initial Bonsai asset

## [1.0.0] - 2018-05-03
### Breaking Changes
- bumped dependency of `sensu-plugin` to 2.4 you can read about it [here](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#240---2018-02-08)

### Added
- Added ability to find machines (@yuri-zubov)

## [0.1.1] - 2018-02-27
### Security
- updated rubocop dependency to `~> 0.51.0` per: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8418 (@majormoses)

## [0.1.0] - 2018-02-26
### Added
- Basic Skel (@majormoses)
- PR template (@majormoses)
- metrics-vsphere.rb: get metrics from vsphere (@yuri-zubov)

### Fixed
- misc repo fixups with travis, changelog, pr templates, appeasing the cops, etc (@majormoses)

### Breaking Changes
- removed ruby 2.0 support (@majormoses)

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-vsphere/compare/1.0.0...HEAD
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-vsphere/compare/0.1.1...1.0.0
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-vsphere/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-vsphere/compare/ec87eef66e3c4f28f13072176c517dc02cd57aa4...0.1.0
