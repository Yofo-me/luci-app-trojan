local nxfs = require "nixio.fs"
local sys  = require "luci.sys"
local http = require "luci.http"
local disp = require "luci.dispatcher"
local util = require "luci.util"
local uci = require"luci.model.uci".cursor()
local fs = require "luci.trojan"
local m, s, sec, o
local trojan = "trojan"


font_red = [[<font color="red">]]
font_green = [[<font color="green">]]
font_off = [[</font>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]

m = Map(trojan)

m:append(Template("trojan/status"))


function IsYamlFile(e)
   e=e or""
   local e=string.lower(string.sub(e,-5,-1))
   return e == ".json"
end
function IsYmlFile(e)
   e=e or""
   local e=string.lower(string.sub(e,-4,-1))
   return e == ".json"
end

--m.pageaction = false
--s.anonymous = true
--s = m:section(TypedSection, "trojan")

local server_table = {}
uci:foreach(trojan, "servers", function(s)
	if s.name then
		server_table[s[".name"]] = "[%s] %s:%s" %{s.name, s.remote_addr, s.remote_port}
	elseif s.remote_addr and s.remote__port then
		server_table[s[".name"]] = "%s:%s" %{s.remote_addr, s.remote_port}
	end
end)

local key_table = {}   
for key,_ in pairs(server_table) do  
    table.insert(key_table,key)  
end 

table.sort(key_table) 


-- [[ Global Setting ]]--
s = m:section(TypedSection, "global")
s.anonymous = true

o = s:option(DummyValue, "version", translate("Trojan-GO"))
o.value = "<span id=\"_version\" style=\"line-height: 2.1em;\">%s</span>" %{''..font_red..bold_on..translate("【 NOT FOUND 】")..bold_off..font_off..''}
o.rawhtml = true

o = s:option(DummyValue, "_client", translate("CLIENT"))
o.value = "<span id=\"_trojan\" style=\"line-height: 2.1em;\">%s</span>" %{''..font_red..bold_on..translate("NOT RUNNING")..bold_off..font_off..''}
o.rawhtml = true

o = s:option(DummyValue, "_dns", translate("PDNSD"))
o.value = "<span id=\"_pdnsd\" style=\"line-height: 2.1em;\">%s</span>" %{''..font_red..bold_on..translate("NOT RUNNING")..bold_off..font_off..''}
o.rawhtml = true



o = s:option(ListValue, "enable", translate("STATUS"))
o.default = "0"
o:value("0", translate("Disable"))
o:value("1", translate("Enable"))

o = s:option(ListValue, "ctype", translate("TYPE"))
o.default = "1"
o:value("1", translate("Server List"))
o:value("2", translate("Upload Config"))

o = s:option(ListValue, "global_config", translate("CONFIG"))
local p,h={}
for t,f in ipairs(fs.glob("/usr/share/trojan/config/*.json"))do
	h=fs.stat(f)
	if h then
    p[t]={}
    p[t].name=fs.basename(f)
    if IsYamlFile(p[t].name) or IsYmlFile(p[t].name) then
       o:value(""..p[t].name)
    end
  end
end
o.rmempty = true
o:depends("ctype", "2")

o = s:option(ListValue, "global_server", translate("SERVER"))
for _,key in pairs(key_table) do o:value(key,server_table[key]) end
o.default = "nil"
o.rmempty = true
o:depends("ctype", "1")

o = s:option(Button,"Manager")
o.title = translate("RULES")
o.inputtitle = translate("RULE MANAGER")
o.inputstyle = "reload"
o.write = function()
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan", "rules"))
end

local apply = luci.http.formvalue("cbi.apply")
if apply then
	luci.sys.call("/etc/init.d/trojan restart >/dev/null 2>&1 &")
end

return m

