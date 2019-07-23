#!/usr/bin/env ruby

require 'rubygems'
require 'uri'
require 'net/https'
require 'json'
require 'pp'

###############################################################################
# The CloudClient module contains general functionality to implement a
# Cloud Client
###############################################################################
module CloudClient

    # OpenNebula version
    VERSION = '5.0.0'

    # #########################################################################
    # Default location for the authentication file
    # #########################################################################
    DEFAULT_AUTH_FILE = ENV["HOME"]+"/.one/one_auth"

    # #########################################################################
    # Gets authorization credentials from ONE_AUTH or default
    # auth file.
    #
    # Raises an error if authorization is not found
    # #########################################################################
    def self.get_one_auth
        if ENV["ONE_AUTH"] and !ENV["ONE_AUTH"].empty? and
            File.file?(ENV["ONE_AUTH"])
            one_auth=File.read(ENV["ONE_AUTH"]).strip.split(':')
        elsif File.file?(DEFAULT_AUTH_FILE)
            one_auth=File.read(DEFAULT_AUTH_FILE).strip.split(':')
        else
            raise "No authorization data present"
        end

        raise "Authorization data malformed" if one_auth.length < 2

        one_auth
    end

    # #########################################################################
    # Starts an http connection and calls the block provided. SSL flag
    # is set if needed.
    # #########################################################################
    def self.http_start(url, timeout, &block)
        host = nil
        port = nil

        if ENV['http_proxy']
            uri_proxy  = URI.parse(ENV['http_proxy'])
            host = uri_proxy.host
            port = uri_proxy.port
        end

        http = Net::HTTP::Proxy(host, port).new(url.host, url.port)

        if timeout
            http.read_timeout = timeout.to_i
        end

        if url.scheme=='https'
            http.use_ssl = true
            http.verify_mode=OpenSSL::SSL::VERIFY_NONE
        end

        begin
            res = http.start do |connection|
                block.call(connection)
            end
        rescue Errno::ECONNREFUSED => e
            str =  "Error connecting to server (#{e.to_s}).\n"
            str << "Server: #{url.host}:#{url.port}"

            return CloudClient::Error.new(str,"503")
        rescue Errno::ETIMEDOUT => e
            str =  "Error timeout connecting to server (#{e.to_s}).\n"
            str << "Server: #{url.host}:#{url.port}"

            return CloudClient::Error.new(str,"504")
        rescue Timeout::Error => e
            str =  "Error timeout while connected to server (#{e.to_s}).\n"
            str << "Server: #{url.host}:#{url.port}"

            return CloudClient::Error.new(str,"504")
        rescue SocketError => e
            str =  "Error timeout while connected to server (#{e.to_s}).\n"

            return CloudClient::Error.new(str,"503")
        rescue
            return CloudClient::Error.new($!.to_s,"503")
        end

        if res.is_a?(Net::HTTPSuccess)
            res
        else
            CloudClient::Error.new(res.body, res.code)
        end
    end

    # #########################################################################
    # The Error Class represents a generic error in the Cloud Client
    # library. It contains a readable representation of the error.
    # #########################################################################
    class Error
        attr_reader :message
        attr_reader :code

        # +message+ a description of the error
        def initialize(message=nil, code="500")
            @message=message
            @code=code
        end

        def to_s()
            @message
        end
    end

    # #########################################################################
    # Returns true if the object returned by a method of the OpenNebula
    # library is an Error
    # #########################################################################
    def self.is_error?(value)
        value.class==CloudClient::Error
    end
end

module OneGate
    module VirtualMachine
        VM_STATE=%w{INIT PENDING HOLD ACTIVE STOPPED SUSPENDED DONE FAILED
            POWEROFF UNDEPLOYED CLONING CLONING_FAILURE}

        LCM_STATE=%w{
            LCM_INIT
            PROLOG
            BOOT
            RUNNING
            MIGRATE
            SAVE_STOP
            SAVE_SUSPEND
            SAVE_MIGRATE
            PROLOG_MIGRATE
            PROLOG_RESUME
            EPILOG_STOP
            EPILOG
            SHUTDOWN
            CANCEL
            FAILURE
            CLEANUP_RESUBMIT
            UNKNOWN
            HOTPLUG
            SHUTDOWN_POWEROFF
            BOOT_UNKNOWN
            BOOT_POWEROFF
            BOOT_SUSPENDED
            BOOT_STOPPED
            CLEANUP_DELETE
            HOTPLUG_SNAPSHOT
            HOTPLUG_NIC
            HOTPLUG_SAVEAS
            HOTPLUG_SAVEAS_POWEROFF
            HOTPLUG_SAVEAS_SUSPENDED
            SHUTDOWN_UNDEPLOY
            EPILOG_UNDEPLOY
            PROLOG_UNDEPLOY
            BOOT_UNDEPLOY
            HOTPLUG_PROLOG_POWEROFF
            HOTPLUG_EPILOG_POWEROFF
            BOOT_MIGRATE
            BOOT_FAILURE
            BOOT_MIGRATE_FAILURE
            PROLOG_MIGRATE_FAILURE
            PROLOG_FAILURE
            EPILOG_FAILURE
            EPILOG_STOP_FAILURE
            EPILOG_UNDEPLOY_FAILURE
            PROLOG_MIGRATE_POWEROFF
            PROLOG_MIGRATE_POWEROFF_FAILURE
            PROLOG_MIGRATE_SUSPEND
            PROLOG_MIGRATE_SUSPEND_FAILURE
            BOOT_UNDEPLOY_FAILURE
            BOOT_STOPPED_FAILURE
            PROLOG_RESUME_FAILURE
            PROLOG_UNDEPLOY_FAILURE
            DISK_SNAPSHOT_POWEROFF
            DISK_SNAPSHOT_REVERT_POWEROFF
            DISK_SNAPSHOT_DELETE_POWEROFF
            DISK_SNAPSHOT_SUSPENDED
            DISK_SNAPSHOT_REVERT_SUSPENDED
            DISK_SNAPSHOT_DELETE_SUSPENDED
            DISK_SNAPSHOT
            DISK_SNAPSHOT_DELETE
            PROLOG_MIGRATE_UNKNOWN
            PROLOG_MIGRATE_UNKNOWN_FAILURE
        }

        SHORT_VM_STATES={
            "INIT"              => "init",
            "PENDING"           => "pend",
            "HOLD"              => "hold",
            "ACTIVE"            => "actv",
            "STOPPED"           => "stop",
            "SUSPENDED"         => "susp",
            "DONE"              => "done",
            "FAILED"            => "fail",
            "POWEROFF"          => "poff",
            "UNDEPLOYED"        => "unde",
            "CLONING"           => "clon",
            "CLONING_FAILURE"   => "fail"
        }

        SHORT_LCM_STATES={
            "PROLOG"            => "prol",
            "BOOT"              => "boot",
            "RUNNING"           => "runn",
            "MIGRATE"           => "migr",
            "SAVE_STOP"         => "save",
            "SAVE_SUSPEND"      => "save",
            "SAVE_MIGRATE"      => "save",
            "PROLOG_MIGRATE"    => "migr",
            "PROLOG_RESUME"     => "prol",
            "EPILOG_STOP"       => "epil",
            "EPILOG"            => "epil",
            "SHUTDOWN"          => "shut",
            "CANCEL"            => "shut",
            "FAILURE"           => "fail",
            "CLEANUP_RESUBMIT"  => "clea",
            "UNKNOWN"           => "unkn",
            "HOTPLUG"           => "hotp",
            "SHUTDOWN_POWEROFF" => "shut",
            "BOOT_UNKNOWN"      => "boot",
            "BOOT_POWEROFF"     => "boot",
            "BOOT_SUSPENDED"    => "boot",
            "BOOT_STOPPED"      => "boot",
            "CLEANUP_DELETE"    => "clea",
            "HOTPLUG_SNAPSHOT"  => "snap",
            "HOTPLUG_NIC"       => "hotp",
            "HOTPLUG_SAVEAS"           => "hotp",
            "HOTPLUG_SAVEAS_POWEROFF"  => "hotp",
            "HOTPLUG_SAVEAS_SUSPENDED" => "hotp",
            "SHUTDOWN_UNDEPLOY" => "shut",
            "EPILOG_UNDEPLOY"   => "epil",
            "PROLOG_UNDEPLOY"   => "prol",
            "BOOT_UNDEPLOY"     => "boot",
            "HOTPLUG_PROLOG_POWEROFF"   => "hotp",
            "HOTPLUG_EPILOG_POWEROFF"   => "hotp",
            "BOOT_MIGRATE"              => "boot",
            "BOOT_FAILURE"              => "fail",
            "BOOT_MIGRATE_FAILURE"      => "fail",
            "PROLOG_MIGRATE_FAILURE"    => "fail",
            "PROLOG_FAILURE"            => "fail",
            "EPILOG_FAILURE"            => "fail",
            "EPILOG_STOP_FAILURE"       => "fail",
            "EPILOG_UNDEPLOY_FAILURE"   => "fail",
            "PROLOG_MIGRATE_POWEROFF"   => "migr",
            "PROLOG_MIGRATE_POWEROFF_FAILURE"   => "fail",
            "PROLOG_MIGRATE_SUSPEND"            => "migr",
            "PROLOG_MIGRATE_SUSPEND_FAILURE"    => "fail",
            "BOOT_UNDEPLOY_FAILURE"     => "fail",
            "BOOT_STOPPED_FAILURE"      => "fail",
            "PROLOG_RESUME_FAILURE"     => "fail",
            "PROLOG_UNDEPLOY_FAILURE"   => "fail",
            "DISK_SNAPSHOT_POWEROFF"        => "snap",
            "DISK_SNAPSHOT_REVERT_POWEROFF" => "snap",
            "DISK_SNAPSHOT_DELETE_POWEROFF" => "snap",
            "DISK_SNAPSHOT_SUSPENDED"       => "snap",
            "DISK_SNAPSHOT_REVERT_SUSPENDED"=> "snap",
            "DISK_SNAPSHOT_DELETE_SUSPENDED"=> "snap",
            "DISK_SNAPSHOT"        => "snap",
            "DISK_SNAPSHOT_DELETE" => "snap",
            "PROLOG_MIGRATE_UNKNOWN" => "migr",
            "PROLOG_MIGRATE_UNKNOWN_FAILURE" => "fail"
        }

        def self.state_to_str(id, lcm_id)
            id = id.to_i
            state_str = VM_STATE[id]

            if state_str=="ACTIVE"
                lcm_id = lcm_id.to_i
                return LCM_STATE[lcm_id]
            end

            return state_str
        end

        def self.print(json_hash)
            OneGate.print_header("VM " + json_hash["VM"]["ID"])
            OneGate.print_key_value("NAME", json_hash["VM"]["NAME"])
            OneGate.print_key_value(
                "STATE",
                self.state_to_str(
                    json_hash["VM"]["STATE"],
                    json_hash["VM"]["LCM_STATE"]))

            vm_nics = [json_hash['VM']['TEMPLATE']['NIC']].flatten
            vm_nics.each { |nic|
                # TODO: IPv6
                OneGate.print_key_value("IP", nic["IP"])
            }
        end
    end

    module Service
        STATE = {
            'PENDING'            => 0,
            'DEPLOYING'          => 1,
            'RUNNING'            => 2,
            'UNDEPLOYING'        => 3,
            'WARNING'            => 4,
            'DONE'               => 5,
            'FAILED_UNDEPLOYING' => 6,
            'FAILED_DEPLOYING'   => 7,
            'SCALING'            => 8,
            'FAILED_SCALING'     => 9,
            'COOLDOWN'           => 10
        }

        STATE_STR = [
            'PENDING',
            'DEPLOYING',
            'RUNNING',
            'UNDEPLOYING',
            'WARNING',
            'DONE',
            'FAILED_UNDEPLOYING',
            'FAILED_DEPLOYING',
            'SCALING',
            'FAILED_SCALING',
            'COOLDOWN'
        ]

        # Returns the string representation of the service state
        # @param [String] state String number representing the state
        # @return the state string
        def self.state_str(state_number)
            return STATE_STR[state_number.to_i]
        end

        def self.print(json_hash)
            OneGate.print_header("SERVICE " + json_hash["SERVICE"]["id"])
            OneGate.print_key_value("NAME", json_hash["SERVICE"]["name"])
            OneGate.print_key_value("STATE", Service.state_str(json_hash["SERVICE"]['state']))
            puts

            roles = [json_hash['SERVICE']['roles']].flatten
            roles.each { |role|
                OneGate.print_header("ROLE " + role["name"], false)

                if role["nodes"]
                    role["nodes"].each{ |node|
                        OneGate::VirtualMachine.print(node["vm_info"])
                    }
                end

                puts
            }
        end
    end

    class Client
        def initialize(opts={})
            @vmid = ENV["VMID"]
            @token = ENV["TOKENTXT"]

            url = opts[:url] || ENV['ONEGATE_ENDPOINT']
            @uri = URI.parse(url)

            @user_agent = "OpenNebula #{CloudClient::VERSION} " <<
                "(#{opts[:user_agent]||"Ruby"})"

            @host = nil
            @port = nil

            if ENV['http_proxy']
                uri_proxy  = URI.parse(ENV['http_proxy'])
                @host = uri_proxy.host
                @port = uri_proxy.port
            end
        end

        def get(path)
            req = Net::HTTP::Proxy(@host, @port)::Get.new(path)

            do_request(req)
        end

        def delete(path)
            req =Net::HTTP::Proxy(@host, @port)::Delete.new(path)

            do_request(req)
        end

        def post(path, body)
            req = Net::HTTP::Proxy(@host, @port)::Post.new(path)
            req.body = body

            do_request(req)
        end

        def put(path, body)
            req = Net::HTTP::Proxy(@host, @port)::Put.new(path)
            req.body = body

            do_request(req)
        end

        def login
            req = Net::HTTP::Proxy(@host, @port)::Post.new('/login')

            do_request(req)
        end

        def logout
            req = Net::HTTP::Proxy(@host, @port)::Post.new('/logout')

            do_request(req)
        end

        private

        def do_request(req)
            req.basic_auth @username, @password

            req['User-Agent'] = @user_agent
            req['X-ONEGATE-TOKEN'] = @token
            req['X-ONEGATE-VMID'] = @vmid

            res = CloudClient::http_start(@uri, @timeout) do |http|
                http.request(req)
            end

            res
        end
    end

    def self.parse_json(response)
        if CloudClient::is_error?(response)
            puts "ERROR: "
            puts response.message
            exit -1
        else
            return JSON.parse(response.body)
        end
    end

    # Sets bold font
    def self.scr_bold
        print "\33[1m"
    end

    # Sets underline
    def self.scr_underline
        print "\33[4m"
    end

    # Restore normal font
    def self.scr_restore
        print "\33[0m"
    end

    # Print header
    def self.print_header(str, underline=true)
        if $stdout.tty?
            scr_bold
            scr_underline if underline
            print "%-80s" % str
            scr_restore
        else
            print str
        end
        puts
    end

    def self.print_key_value(key, value)
        puts "%-20s: %-20s" % [key, value]
    end

    def self.help_str
        return <<-EOT
Available commands
    $ onegate vm show [VMID] [--json]

    $ onegate vm update [VMID] --data KEY=VALUE[\\nKEY2=VALUE2]

    $ onegate vm ACTION VMID
        $ onegate vm resume VMID
        $ onegate vm stop VMID
        $ onegate vm suspend VMID
        $ onegate vm delete VMID [--hard]
        $ onegate vm terminate VMID [--hard]
        $ onegate vm reboot VMID [--hard]
        $ onegate vm poweroff VMID [--hard]
        $ onegate vm resubmit VMID
        $ onegate vm resched VMID
        $ onegate vm unresched VMID
        $ onegate vm hold VMID
        $ onegate vm release VMID

    $ onegate service show [--json]

    $ onegate service scale --role ROLE --cardinality CARDINALITY
EOT
    end
end


require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.on("-d", "--data DATA", "Data to be included in the VM") do |data|
    options[:data] = ''

    data.split("\\n").each do |d|
      data   = d.split('=', 2)
      key    = data[0]
      values = data[1]

      values = values.split(',') # value can be multiple

      values.map! do |value|
        value = value.split('=')

        if value.size > 1
          # value is multiple
          k = value[0]
          v = value[1]

          if v.include?(' ') && !v.include?('"')
            if v[-1] == ']' # value is the last in the list
              v = "\"#{v[0..-2]}\"#{v[-1]}"
            else
              v = "\"#{v}\""
            end
          end

          "#{k}=#{v}"
        else
          # value is single
          v = value[0]

          v = "\"#{v}\"" if v.include?(' ') && !v.include?('"')

          v
        end
      end

      options[:data] += "#{key}=#{values.join(',')}\n"
    end
  end

  opts.on("-r", "--role ROLE", "Service role") do |role|
    options[:role] = role
  end

  opts.on("-c", "--cardinality CARD", "Service cardinality") do |cardinality|
    options[:cardinality] = cardinality
  end

  opts.on("-j", "--json", "Print resource information in JSON") do |json|
    options[:json] = json
  end

  opts.on("-f", "--hard", "Hard option for power off operations") do |hard|
    options[:hard] = hard
  end

  opts.on("-h", "--help", "Show this message") do
    puts OneGate.help_str
    exit
  end
end.parse!

client = OneGate::Client.new()

case ARGV[0]
when "vm"
    case ARGV[1]
    when "show"
        if ARGV[2]
            response = client.get("/vms/"+ARGV[2])
        else
            response = client.get("/vm")
        end

        json_hash = OneGate.parse_json(response)
        if options[:json]
            puts JSON.pretty_generate(json_hash)
        else
            OneGate::VirtualMachine.print(json_hash)
        end
    when "update"
        if !options[:data]
            puts "You have to provide the data as a param (--data)"
            exit -1
        end

        if ARGV[2]
            response = client.put("/vms/"+ARGV[2], options[:data])
        else
            response = client.put("/vm", options[:data])
        end

        if CloudClient::is_error?(response)
            puts "ERROR: "
            puts response.message
            exit -1
        end
    when "resume",
         "stop",
         "suspend",
         "delete",
         "terminate",
         "reboot",
         "poweroff",
         "resubmit",
         "resched",
         "unresched",
         "hold",
         "release"
        if ARGV[2]
            action_hash = {
                "action" => {
                    "perform" => ARGV[1]
                }
            }

            if options[:hard]
                action_hash["action"]["params"] = true
            end

            response = client.post("/vms/"+ARGV[2]+"/action", action_hash.to_json)

            if CloudClient::is_error?(response)
                puts "ERROR: "
                puts response.message
                exit -1
            end
        else
            puts "You have to provide a VM ID"
            exit -1
        end
    else
        puts OneGate.help_str
        puts
        puts "Action #{ARGV[1]} not supported"
        exit -1
    end
when "service"
    case ARGV[1]
    when "show"
        response = client.get("/service")
        json_hash = OneGate.parse_json(response)
        #pp json_hash
        if options[:json]
            puts JSON.pretty_generate(json_hash)
        else
            OneGate::Service.print(json_hash)
        end
    when "scale"
        response = client.put(
            "/service/role/" + options[:role],
            {
                :cardinality => options[:cardinality]
            }.to_json)

        if CloudClient::is_error?(response)
            puts "ERROR: "
            puts response.message
            exit -1
        end
    else
        puts OneGate.help_str
        puts
        puts "Action #{ARGV[1]} not supported"
        exit -1
    end
else
    puts OneGate.help_str
    exit -1
end

