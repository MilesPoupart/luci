--[[
LuCI - Lua Configuration Interface

Copyright 2011 flyzjhz <flyzjhz@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

local wa = require "luci.tools.webadmin"
local fs = require "nixio.fs"
local util = require "nixio.util"
local SYS  = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local lanipaddr = uci:get("network", "lan", "ipaddr") or "192.168.1.1"
--- Retrieves the output of the "get_verysync_port" command.
-- @return	String containing the current get_verysync_port

local verysyncport = uci:get("verysync", "setting", "port") or "88"

local running=(luci.sys.call("pidof verysync > /dev/null") == 0)

local verysync_version=translate("Unknown")
local verysync_bin="/usr/bin/verysync"
if not fs.access(verysync_bin)  then
	-- verysync_version=translate("Not exist")
	verysync_version= translate("The program will be automatically downloaded when the settings are applied, please refresh the page later to check the results.")
else
	verysync_version=SYS.exec("cat /etc/verysync_version")
	if not verysync_version or verysync_version == "" then
		verysync_version = translate("Unknown")
	end
end

-- if running then
-- 	m = Map("verysync", translate("verysync"), "<b><font color=\"green\">微力同步正在运行!</font></b>")
-- else
-- 	m = Map("verysync", translate("verysync"), "<b><font color=\"red\">" .. translate("微力同步未启动") .. "</font></b>")
-- end

m = Map("verysync")
m.title	= translate("Verysync")
m.description = translate("Simple and easy-to-use multi-platform file synchronization software, astonishing transmission speed is different from the greatest advantage of other products. Micro-force synchronization of intelligent P2P technology to accelerate synchronization, will split the file into several KB-only data synchronization, and the file will be AES encryption processing.")

m:section(SimpleSection).template  = "verysync/verysync_status"
s = m:section(NamedSection, "setting", "verysync", translate("Settings"), translate("This is the standalone executable version (luci-app-verysync-standalone), if the non-standalone executable version (luci-app-verysync) is installed at the same time, it may cause problems! If you have verysync already installed or pre-installed, please uninstall this plug-in (luci-app-verysync-standalone) and install the non-standalone downloadable executable version (luci-app-verysync)"))

s.anonymous = true
s.addremove = false

enable = s:option(Flag, "enable",  translate("Enable"))
enable.default = false
enable.optional = false
enable.rmempty = false

function enable.write(self, section, value)
	if value == "0" then
		os.execute("/etc/init.d/verysync disable")
		os.execute("/etc/init.d/verysync stop")
	else
		os.execute("/etc/init.d/verysync enable")
	end
	Flag.write(self, section, value)
end

e=s:option(DummyValue,"verysync_version",translate("Verysync Version"))
e.rawhtml  = true
e.value ="<b>"..verysync_version.."</b>"

e=s:option(DummyValue,"official_site",translate("Official Site"))
e.rawhtml  = true
e.value ="<strong><a target=\"_blank\" href='http://www.verysync.com/'><font color=\"red\">http://www.verysync.com/</font></a></strong>"

e=s:option(DummyValue,"official_forum",translate("Official Forum"))
e.rawhtml  = true
e.value ="<strong><a target=\"_blank\" href='https://forum.verysync.com/'><font color=\"red\">https://forum.verysync.com/</font></a></strong>"

-- e=s:option(DummyValue,"verysync_url",translate("执行文件手动下载"))
-- e.rawhtml  = true
-- e.value ="<strong><a target=\"_blank\" href='https://github.com/verysync/releases/releases'><font color=\"red\">https://github.com/verysync/releases/releases</font></a></strong>"

delay = s:option(Value, "delay", translate("Delay Start (s)"))
delay:value("20", translate("20"))
delay:value("40", translate("40"))
delay:value("60", translate("60"))
delay:value("80", translate("80"))
delay:value("100", translate("100"))
delay:value("120", translate("120"))

local devices = {}
util.consume((fs.glob("/mnt/sd??*")), devices)
device = s:option(Value, "device", translate("Mount Point"), translate("The mount point where the Verysync software directory is located."))
for i, dev in ipairs(devices) do
	device:value(dev)
end
if nixio.fs.access("/etc/config/verysync") then
	device.titleref = luci.dispatcher.build_url("admin", "system", "fstab")
end

port = s:option(Value, "port", translate("Port"), translate("Customize the port number of the Verysync management interface."))
port:value("8886", "8886")
port:value("8889", "8889")

port.datatype = "port"
port.default = "88"
port.optional = true
port.rmempty = true


if not nixio.fs.access("/usr/bin/verysync") then
downloadfile=1
end

if downloadfile==1 then

dl_mod = s:option(ListValue, "dl_mod", translate("Download Mode"), translate("Choose the way to download the executable files.").."<br/>"..translate("You can also use the customized download URL or download manually then upload it to /tmp/upload/ via \"System - FileTransfer\"").."<br/>"..translate("The software will detect and run automatically when it starts!"))
-- dl_mod:value("git", "GIT下载")
-- dl_mod:value("verysync", "默认下载")
dl_mod:value("verysync", translate("Verysync Official Server"))
dl_mod:value("custom", translate("Customize Download URL or Upload Manually"))

-- dl_mod.default = "git"
dl_mod.default = "verysync"
dl_mod.optional = true
dl_mod.rmempty = true

-- e = s:option(Button, "get_verysync_version", translate("获取版本"), translate("从官方获取可下载软件的版本，获取版本后约30秒须刷新一次界面。"))
-- e.inputtitle = translate("获取版本")
-- e.inputstyle = "apply"

-- function e.write(self, section)
-- 	os.execute("/usr/bin/verysync_ver")
-- 	self.inputtitle = translate("获取版本")
-- end
-- e:depends("dl_mod", "git")

-- get_verysync_ver = s:option(Value, "get_verysync_ver", translate("获取版本命令"), ("在此可编辑获取github上版本信息的命令。"))
-- get_verysync_ver.template = "cbi/tvalue"
-- get_verysync_ver.rows = 2
-- get_verysync_ver.wrap = "off"
-- get_verysync_ver:depends("dl_mod", "git")

-- if not nixio.fs.access("/usr/bin/verysync_ver") then
-- 	os.execute("touch /usr/bin/verysync_ver && chmod 0755 /usr/bin/verysync_ver")
-- end

-- function get_verysync_ver.cfgvalue(self, section)
-- 	return fs.readfile("/usr/bin/verysync_ver") or ""
-- end

-- function get_verysync_ver.write(self, section, value)
-- 	if value then
-- 		value = value:gsub("\r\n?", "\n")
-- 		fs.writefile("/tmp/verysync_ver", value)
-- 		if (luci.sys.call("cmp -s /tmp/verysync_ver /usr/bin/verysync_ver") == 1) then
-- 			fs.writefile("/usr/bin/verysync_ver", value)
-- 		end
-- 		fs.remove("/tmp/verysync_ver")
-- 	end
-- end

e = s:option(Button, "get_verysync_version_d", translate("Get Verysync Version"), translate("Get the downloadable version of the software from the official server.").."<br/>"..translate("Please manually refresh the page about 30 seconds after getting the version."))
e.inputtitle = translate("Get Verysync Version")
e.inputstyle = "apply"

function e.write(self, section)
	-- os.execute("curl -k -s http://releases-cdn.verysync.com/releases/ |grep -E \"..*href..*v\" |sed 's/^..*>v//g'|awk -F '/' '{print $1}' |sort -r >/tmp/log/verysync_version_d &")
	os.execute("curl -k -s http://www.verysync.com/shell/latest|grep v|tr -d v>/tmp/log/verysync_version_d &")
	self.inputtitle = translate("Get Verysync Version")
end
e:depends("dl_mod", "verysync")

-- e = s:option(ListValue, "version_g","下载执行文件版本", "git下载时，需要先执行上面的获取版本，并刷新页面。")
-- for i_1 in io.popen("cat /tmp/log/verysync_version", "r"):lines() do
--     e:value(i_1)
-- end
-- e:depends("dl_mod", "git")

e = s:option(ListValue, "version_d",translate("Download Executable Version"))
for i_1 in io.popen("cat /tmp/log/verysync_version_d", "r"):lines() do
    e:value(i_1)
end
e:depends("dl_mod", "verysync")

end

e = s:option(Value, "c_url", translate("Customize Download URL"), translate("The URL must start with http or https and contains the full file name!"))
e:depends("dl_mod", "custom")

e = s:option(DummyValue, "manual", translate("Upload Manually"), translate("Click to the page for manually uploading files (luci-app-filetransfer required) or use other tools and upload the file to /tmp/upload/.").."<br/>"..translate("After uploading files, start the software on this page and it will be installed automatically."))
if nixio.fs.access("/etc/config/verysync") then
	e.titleref = luci.dispatcher.build_url("admin", "system", "filetransfer")
end
e:depends("dl_mod", "custom")

-- e=s:option(DummyValue,"verysyncweb",translate("Open the verysync Webui"))
-- e.rawhtml  = true
-- e.value ="<strong><a target=\"_blank\" href='http://"..lanipaddr..":"..verysyncport.."'><font color=\"red\">打开verysync软件控制界面</font></a></strong>"

s:option(Flag, "more", translate("More Options"))

e = s:option(Button, "del_sync", translate("Reset Verysync"), translate("Sometimes the downloaded files are incorrect, you can delete them.").."<br/> <font color=\"Red\"><strong>"..translate("Delete files only after multiple startup failures. When the synchronization is successful, it must not be deleted!!").."</strong></font>")
e.inputtitle = translate("Reset Verysync")
e.inputstyle = "apply"

function e.write(self, section)
	os.execute("/usr/bin/del_verysync.sh &")
	self.inputtitle = translate("Reset Verysync")
end
e:depends("more", "1")

return m

