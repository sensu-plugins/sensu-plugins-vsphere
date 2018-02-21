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
class VsphereGraphite < Sensu::Plugin::Metric::CLI::Generic
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

  option :host_name,
         description: 'Host name.',
         short: '-h HOST_NAME',
         long: '--host_name HOST_NAME'

  option :data_center,
         description: 'Data center name.',
         short: '-D DATA_CENTER_NAME',
         long: '--data_center_name DATA_CENTER_NAME'

  option :compute_resource,
         description: 'Compute resource name.',
         short: '-c COMPUTE_RESOURCE_NAME',
         long: '--compute_resource COMPUTE_RESOURCE_NAME'

  option :command_type,
         description: 'Specify command type (CPU, MEM, NET, IO, VMFS, RUNTIME, ...)',
         short: '-l COMMAND_TYPE',
         long: '--command_type COMMAND_TYPE'

  option :insecure,
         description: 'Use insecure connection',
         short: '-i',
         long: '--insecure',
         default: false

  option :period,
         description: ' Sampling Period in seconds. Basic historic intervals: 300, 1800, 7200 or 86400. See config for any changes.',
         short: '-r PERIOD',
         long: '--period PERIOD',
         proc: proc(&:to_i),
         default: 300

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-S SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.vsphere"

  option :find_resource,
         description: 'Help to find resource and path to it',
         long: '--find_resource NAME'

  def vim
    @vim ||= RbVmomi::VIM.connect(
      host: config[:host],
      user: config[:user],
      password: config[:password],
      insecure: config[:insecure]
    )
  end

  def build_tree_resources(datacenters)
    result = {}
    datacenters.grep(RbVmomi::VIM::Datacenter) do |datacenter|
      result[datacenter] ||= {}
      datacenter.hostFolder.children.grep(RbVmomi::VIM::ComputeResource) do |compute_resource|
        result[datacenter][compute_resource] ||= {}
        compute_resource.host.grep(RbVmomi::VIM::HostSystem) do |host_system|
          result[datacenter][compute_resource][host_system] ||= {}
          host_system.vm.grep(RbVmomi::VIM::VirtualMachine) do |virtual_machine|
            result[datacenter][compute_resource][host_system][virtual_machine] = nil
          end
        end
      end
    end
    result
  end

  def find_resource_by_name(resources, name, path = '')
    result = []
    resources.each do |key, value|
      new_path = "#{path}=> #{key.name}"
      if key.name == name
        result << new_path
      end

      result += find_resource_by_name(value, name, new_path) if value
    end

    result
  end

  def find_or_take_first(resources, resource_name)
    result = nil
    if resource_name
      result = resources.find { |x| x.name == resource_name }
      unless result
        unknown "#{resources.first.class.to_s.gsub(/^.*::/, '')}(#{resource_name}) wasn't found. Available(#{resources.map(&:name)})"
      end
    elsif resources.length == 1
      result = resources.first
    else
      if resources.first.is_a?(RbVmomi::VIM::ComputeResource)
        unknown "please use  --compute_resource (#{resources.map(&:name)})"
      end
      if resources.first.is_a?(RbVmomi::VIM::HostSystem)
        unknown "please use  --host_name (#{resources.map(&:name)})"
      end
      if resources.first.is_a?(RbVmomi::VIM::Datacenter)
        unknown "please use  --data_center_name (#{resources.map(&:name)})"
      end
    end
    result
  end

  def run
    data_centers = vim.serviceInstance.content.rootFolder.childEntity.grep(RbVmomi::VIM::Datacenter)

    if config[:find_resource]
      result = find_resource_by_name(build_tree_resources(data_centers), config[:find_resource])
      if result.empty?
        puts 'Not found'
      else
        result.each do |line|
          puts line
        end
      end
      ok
    else
      dc = find_or_take_first(data_centers, config[:data_center])
      pm = vim.serviceInstance.content.perfManager

      compute_resources = dc.hostFolder.children.grep(RbVmomi::VIM::ComputeResource)
      if config[:vm_name] || config[:host_name] || config[:compute_resource]
        compute_resource = find_or_take_first(compute_resources, config[:compute_resource])
      end
      host = find_or_take_first(compute_resource.host, config[:host_name]) if config[:vm_name] || config[:host_name]

      if config[:vm_name]
        vms = host.vm.grep(RbVmomi::VIM::VirtualMachine)
        resource = find_or_take_first(vms, config[:vm_name])
      elsif config[:host_name]
        resource = host
      elsif config[:compute_resource] && compute_resource.is_a?(RbVmomi::VIM::ClusterComputeResource)
        resource = compute_resource
      else
        resource = dc
      end

      regexp = Regexp.new("^#{config[:command_type]}")
      metrics = pm.retrieve_stats([resource],
                                  [],
                                  multi_instance: true, interval: config[:period],
                                  start_time: (Time.now - config[:period] * 10))

      if metrics
        timestamp = metrics[resource][:sampleInfo].first[:timestamp].to_i
        filtered_metrics = metrics[resource][:metrics].select { |(metric, _), _| metric.to_s.match(regexp) && metric }
        filtered_metrics.each do |(metric, instance), value|
          output(
            metric_name: "#{config[:scheme]}.#{[instance, metric].flatten.reject { |e| e == '' }.join('.')}",
            value: value.first,
            timestamp: timestamp
          )
        end

        ok
      else
        warning
      end
    end
  end
end
