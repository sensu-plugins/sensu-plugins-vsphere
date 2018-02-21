#! /usr/bin/env ruby
#
#   metrics-vsphere
#
# DESCRIPTION:
#
# OUTPUT:
#   plain text, metric data, etc
#
# PLATFORMS:
#   Linux, Windows, BSD, Solaris, etc
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rbvmomi
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Yuri Zubov  <yury.zubau@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'rbvmomi'

#
# VSphere Graphite
#
class VsphereGraphite < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
         description: 'ESX or ESXi hostname',
         short: '-H HOST',
         long: '--host HOST'

  option :user,
         description: 'Username to connect with',
         short: '-u USER',
         long: '--user USER'

  option :password,
         description: 'Password to use with the username.',
         short: '-p PASSWORD',
         long: '--password PASSWORD'

  option :vm_name,
         description: 'Virtual machine name.',
         short: '-N VM_NAME',
         long: '--name VM_NAME'

  option :command_type,
         description: 'Specify command type (CPU, MEM, NET, IO, VMFS, RUNTIME, ...)',
         short: '-l COMMAND_TYPE',
         long: '--command_type COMMAND_TYPE'

  option :insecure,
         description: 'Use insecure connection',
         short: '-i',
         long: '--insecure',
         default: false

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-S SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.vsphere"

  def vim
    @vim ||= RbVmomi::VIM.connect(
      host: config[:host],
      user: config[:user],
      password: config[:password],
      insecure: config[:insecure]
    )
  end

  def run
    dc = vim.serviceInstance.find_datacenter
    pm = vim.serviceInstance.content.perfManager
    if config[:vm_name]
      resource = dc.vmFolder.childEntity.grep(RbVmomi::VIM::VirtualMachine).find { |x| x.name == config[:vm_name] }
    else
      resource = dc.hostFolder.children.first.host.first
    end

    regexp = Regexp.new("^#{config[:command_type]}")
    metrics = pm.retrieve_stats([resource], [], {})[resource][:metrics].select{ |metric, _| metric.to_s.match(regexp) }
    metrics.each do |metric, value|
      output "#{config[:scheme]}.#{metric}", value.first
    end

    ok
  end
end
