#! /opt/sensu/embedded/bin/ruby

require 'sensu-plugin/check/cli'
require 'rbvmomi'
require 'json'

class ESXi_Check < Sensu::Plugin::Check::CLI
  check_name nil
  option :host,
         short: '-H HOST',
         long: '--host HOST',
         default: 'localhost',
         description: 'ESXi host'

  option :verify_ssl,
         description: 'Turn on/off using SSL certificate (default: false)',
         short: '-v',
         long: '--verify_ssl',
         boolean: true,
         default: false

  option :username,
         short: '-u USERNAME',
         long: '--username USERNAME',
         default: 'root',
         description: 'API username'

  option :password,
         short: '-p PASSWORD',
         long: '--password PASSWORD',
         default: 'root',
         description: 'API password'

  option :dryrun,
         short: '-d',
         long: '--dryrun',
         description: 'run without sending to sensu but see what would be sent',
         boolean: true,
         default: false

  option :handlers,
         description: 'Comma separated list of handlers',
         long: '--handlers <HANDLER>',
         proc: proc { |s| s.split(',') },
         default: []

  option :help,
         short: '-h',
         long: '--help',
         description: 'Show this message',
         on: :tail,
         boolean: true,
         show_options: true,
         exit: 0

  def send_client_socket(data)
    if config[:dryrun]
      puts data.inspect
    else
      sock = UDPSocket.new
      sock.send(data + "\n", 0, '127.0.0.1', 3030)
    end
  end

  def send_ok(check_name, msg, source)
    event = {
      'name' => check_name,
      'source' => source,
      'status' => 0,
      'output' => "#{self.class.name} OK: #{msg}",
      'handlers' => config[:handlers]
    }
    send_client_socket(event.to_json)
  end

  def send_warning(check_name, msg, source)
    u = URI.parse(config[:host])
    event = {
      'name' => check_name,
      'source' => source,
      'status' => 1,
      'output' => "#{self.class.name} WARNING: #{msg}",
      'handlers' => config[:handlers],
      'occurrences' => 2,
    }
    send_client_socket(event.to_json)
  end

  def send_critical(check_name, msg, source)
    u = URI.parse(config[:host])
    event = {
      'name' => check_name,
      'source' => source,
      'status' => 2,
      'output' => "#{self.class.name} CRITICAL: #{msg}",
      'handlers' => config[:handlers],
      'occurrences' => 2,
    }
    send_client_socket(event.to_json)
  end

  def send_unknown(check_name, msg)
    event = {
      'name' => check_name,
      'source' => source,
      'status' => 3,
      'output' => "#{self.class.name} UNKNOWN: #{msg}",
      'handlers' => config[:handlers]
    }
    send_client_socket(event.to_json)
  end

  def Cachefile(data)
    file = File.open('/var/log/sensu/vmware-plugin.json', 'w')
    file.puts data
    file.close
  end

  def Readfile()
    if File.file?('/var/log/sensu/vmware-plugin.json')
      file = File.read('/var/log/sensu/vmware-plugin.json')
      json = JSON.parse(file)
      return json
    end
    return {}
  end

  def run
    readcache = Readfile()
    cachewrite = {}
    u = URI.parse(config[:host])
    vim = RbVmomi::VIM.connect host: u.host, user: config[:username], password: config[:password], insecure: config[:verify_ssl]
    rootFolder = vim.serviceInstance.content.rootFolder
    dc = rootFolder.childEntity
    dc.each do |d|
      d.hostFolder.childEntity.each do |h|
        h.host.each do |hs|
          if hs.summary.overallStatus == 'red'
            hs.triggeredAlarmState.each do |a|
              msg = "#{hs.name} currently has an alarm #{hs.summary.overallStatus} - #{a.alarm.info.name}"
              cachewrite["#{hs.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm"] = hs.name
              send_critical("#{hs.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm", msg, hs.name)
              readcache.delete("#{hs.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm")
            end
          elsif hs.summary.overallStatus == 'yellow'
            hs.triggeredAlarmState.each do |a|
              msg = "#{hs.name} currently has an alarm #{hs.summary.overallStatus} - #{a.alarm.info.name}"
              cachewrite["#{hs.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm"] = hs.name
              send_critical("#{hs.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm", msg, hs.name)
              readcache.delete("#{hs.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm")
            end
          else
            msg = "#{hs.name} currently has no alarms"
            send_ok("#{hs.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm", msg, hs.name)
          end
        end
      end
      if d.triggeredAlarmState.any?
        d.triggeredAlarmState.each do |a|
          if a.overallStatus == 'red'
            unless cachewrite.key?("#{a.entity.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm")
              msg = "#{a.entity.name} currently has an alarm #{a.overallStatus} - #{a.alarm.info.name}"
              cachewrite["#{a.entity.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm"] = "ESXi_DC_#{d.name}"
              send_critical("#{a.entity.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm", msg, "ESXi_DC_#{d.name}")
              readcache.delete("#{a.entity.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm")
            end
          elsif a.overallStatus == 'yellow'
            unless cachewrite.key?("#{a.entity.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm")
              msg = "#{a.entity.name} currently has an alarm #{a.overallStatus} - #{a.alarm.info.name}"
              cachewrite["#{a.entity.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm"] = "ESXi_DC_#{d.name}"
              send_warning("#{a.entity.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm", msg, "ESXi_DC_#{d.name}")
              readcache.delete("#{a.entity.name.gsub!(/[^0-9A-Za-z]/, '')}_Alarm")
            end
          end
        end
      else
        msg = "ESXi_DC_#{d.name} currently has no alarms"
        send_ok('ESXi_Alarm', msg, "ESXi_DC_#{d.name}")
      end
    end
    readcache.each do|k,v|
      send_ok(k, 'Alarm has cleared or no longer alerting', v)
    end
    Cachefile(cachewrite.to_json)
    ok
  end
end