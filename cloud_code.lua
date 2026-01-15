AlertDialog.Builder(activity)
.setTitle("提示9494")
.setMessage("云函数执行成功")
.setPositiveButtpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endpeizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  添加日志("=== 云函数编辑器日志 === " .. os.date("%Y-%m-%d %H:%M:%S"))
  import "android.content.ClipData"
  import "android.content.ClipboardManager"
  import "android.content.Context"
  local function 复制到剪贴板(文本)
    local clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("日志", 文本)
    clipboard.setPrimaryClip(clip)
    return true
  end
  local function 正确Base64编码(data)
    添加日志("[DEBUG] 开始Base64编码，数据长度: "..#data)
    local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result=''
    local len = #data
    for i=1,len,3 do
      local a,b,c=data:byte(i,i+2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      result = result .. b64:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
      result = result .. b64:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
      if b then
        result = result .. b64:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
      else
        result = result .. "="
      end
      if c then
        result = result .. b64:sub(n%64+1, n%64+1)
      else
        result = result .. "="
      end
    end
    添加日志("[DEBUG] Base64编码完成，结果长度: "..#result)
    return result
  end
  添加日志("[1] 开始请求云函数: "..云函数链接)
  Http.get(云函数链接.."?t="..os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[2] HTTP响应状态: "..code)
    添加日志("[2] 响应内容长度: "..(content and #content or 0))
    if code == 200 then
      local edit = EditText(activity)
      edit.setLayoutParams(LinearLayout.LayoutParams(-1, 400))
      edit.setText(content)
      edit.setTextSize(14)
      local 当前编辑框 = edit
      AlertDialog.Builder(activity)
      .setTitle("编辑云函数")
      .setView(edit)
      .setPositiveButton("保存", function()
        添加日志("[3] 用户点击保存按钮")
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("[3] 新代码长度: "..#新代码)
        添加日志("[3] 新代码前50字符: "..新代码:sub(1,50):gsub("\n", "\\n"))
        local token = "TOKEN_REMOVED"
        local token预览 = token:sub(1,4).."..."..token:sub(-4)
        添加日志("[4] 使用Token: "..token预览)
        添加日志("[4] Token完整长度: "..#token)
        local 新代码清理 = 新代码:gsub("TOKEN_REMOVED", "TOKEN_REMOVED")
        添加日志("[5] 清理Token后代码长度: "..#新代码清理)
        添加日志("[5] Token清理状态: "..(新代码:find(token) and "✅ 已清理" or "⚠️ 未找到Token"))
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("[6] Base64编码结果长度: "..#base64内容)
        添加日志("[6] Base64前60字符: "..base64内容:sub(1,60))
        添加日志("[6] Base64末尾60字符: "..base64内容:sub(-60))
        local 测试文本 = "Hello"
        local 测试结果 = 正确Base64编码(测试文本)
        添加日志("[TEST] Hello Base64: "..测试结果)
        添加日志("[TEST] 应为: SGVsbG8=")
        添加日志("[TEST] 匹配: "..(测试结果=="SGVsbG8=" and "✅" or "❌"))
        local apiUrl = "https://api.github.com/repos/198013aaa-arch/cloud_code/contents/cloud_code.lua"
        添加日志("[7] 开始获取SHA")
        local json = require("cjson")
        Http.get(apiUrl, nil, "UTF-8", {Authorization="token "..token}, function(getCode, getResp)
          添加日志("[8] SHA响应状态: "..getCode)
          if getCode == 200 then
            local ok, fileInfo = pcall(json.decode, getResp)
            if ok and fileInfo then
              local sha = fileInfo.sha
              添加日志("[9] SHA: "..sha:sub(1,10).."...")
              local updateData = {
                message = "云函数更新 - "..os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha
              }
              local json数据 = json.encode(updateData)
              添加日志("[10] 上传数据长度: "..#json数据)
              添加日志("[10] JSON预览: "..json数据:sub(1,100):gsub("\n", "\\n"))
              local headers = {
                Authorization="token "..token,
                ["Content-Type"]="application/json",
                ["Accept"]="application/vnd.github.v3+json"
              }
              Http.put(apiUrl, json数据, headers, function(putCode, putResp)
                添加日志("[11] 上传结果: "..putCode)
                local 对话框 = AlertDialog.Builder(activity)
                if putCode == 200 then
                  添加日志("[SUCCESS] 上传成功")
                  对话框.setTitle("✅ 上传成功").setMessage("代码已保存到GitHub")
                else
                  添加日志("[ERROR] 上传失败")
                  local errMsg = "状态码: "..putCode
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp.message then
                      errMsg = errMsg.."\n"..resp.message
                      添加日志("[ERROR] GitHub错误: "..resp.message)
                      if resp.message:find("Secret detected") then
                        添加日志("[ERROR] 检测到密钥泄露，已自动清理Token")
                        添加日志("[ERROR] 建议: 1. 撤销当前Token 2. 生成新Token 3. 使用环境变量")
                      end
                    end
                  end
                  对话框.setTitle("❌ 保存失败").setMessage(errMsg)
                end
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "已复制", 800).show()
                end).setNeutralButton("查看详情", function()
                  AlertDialog.Builder(activity)
                  .setTitle("上传详情")
                  .setMessage("新代码长度: "..#新代码.."\n清理后长度: "..#新代码清理.."\nBase64长度: "..#base64内容.."\nSHA: "..(sha and sha:sub(1,20).."..." or "无"))
                  .setPositiveButton("确定", nil)
                  .show()
                end).setNegativeButton("关闭", nil).show()
              end)
            else
              添加日志("[ERROR] SHA解析失败")
            end
          else
            添加日志("[ERROR] 获取SHA失败: "..getCode)
          end
        end)
      end).setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消")
        AlertDialog.Builder(activity).setTitle("已取消").setMessage("操作已取消").setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "已复制", 800).show()
        end).setNegativeButton("关闭", nil).show()
      end).show()
    else
      添加日志("[ERROR] 读取失败: "..code)
      AlertDialog.Builder(activity).setTitle("读取失败").setMessage("状态码: "..code).setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "已复制", 800).show()
      end).setNegativeButton("确定", nil).show()
    end
  end)
endon("确定",nil)
.show()