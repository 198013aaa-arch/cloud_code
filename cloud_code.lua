AlertDialog.Builder(activity)
.setTitle("提示9494")
.setMessage("云函数执行成功")
.setPositiveButton("确定",nil)
.show()
peizhi.onClick = function()
  local 云函数链接 = "https://cdn.jsdelivr.net/gh/198013aaa-arch/cloud_code/cloud_code.lua"
  local 日志内容 = ""
  
  local function 添加日志(内容)
    日志内容 = 日志内容 .. 内容 .. "\n"
  end
  
  添加日志("=== GitHub官方API规范化版本 ===")
  添加日志("API版本: 2022-11-28")
  添加日志("操作时间: " .. os.date("%Y-%m-%d %H:%M:%S"))
  
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
    添加日志("[DEBUG] Base64编码开始，数据长度: " .. #data)
    local b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result = ''
    local len = #data
    
    for i = 1, len, 3 do
      local a, b, c = data:byte(i, i + 2)
      local n = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
      
      result = result .. b64:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
      result = result .. b64:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
      
      if b then
        result = result .. b64:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
      else
        result = result .. "="
      end
      
      if c then
        result = result .. b64:sub(n % 64 + 1, n % 64 + 1)
      else
        result = result .. "="
      end
    end
    
    添加日志("[DEBUG] Base64编码完成，结果长度: " .. #result)
    return result
  end
  
  -- GitHub API配置
  local github配置 = {
    owner = "198013aaa-arch",
    repo = "cloud_code",
    path = "cloud_code.lua",
    token = "TOKEN_REMOVED",
    api版本 = "2022-11-28"
  }
  
  local function 构建API头()
    return {
      Authorization = "token " .. github配置.token,
      Accept = "application/vnd.github+json",
      ["X-GitHub-Api-Version"] = github配置.api版本,
      ["User-Agent"] = "LuaAppX-Pro/1.0"
    }
  end
  
  local function 构建API地址(操作)
    if 操作 == "获取内容" then
      return string.format("https://api.github.com/repos/%s/%s/contents/%s", 
        github配置.owner, github配置.repo, github配置.path)
    elseif 操作 == "更新内容" then
      return string.format("https://api.github.com/repos/%s/%s/contents/%s", 
        github配置.owner, github配置.repo, github配置.path)
    end
  end
  
  添加日志("[1] 初始化GitHub API客户端")
  添加日志("仓库: " .. github配置.owner .. "/" .. github配置.repo)
  添加日志("文件路径: " .. github配置.path)
  
  添加日志("[2] 获取云函数内容: " .. 云函数链接)
  Http.get(云函数链接 .. "?t=" .. os.time(), nil, "UTF-8", nil, function(code, content)
    添加日志("[3] HTTP响应: " .. code)
    添加日志("内容长度: " .. (content and #content or 0))
    
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
        添加日志("[4] 用户点击保存按钮")
        
        local 新代码 = 当前编辑框.getText().toString()
        添加日志("新代码长度: " .. #新代码)
        添加日志("代码预览(前50字符): " .. 新代码:sub(1, 50):gsub("\n", "\\n"))
        
        -- 清理代码中的敏感信息
        local 新代码清理 = 新代码:gsub(github配置.token, "TOKEN_REMOVED")
        添加日志("Token清理状态: " .. (新代码:find(github配置.token) and "✅ 已清理" or "✅ 未发现"))
        
        -- 测试Base64编码
        local 测试结果 = 正确Base64编码("Hello")
        添加日志("[TEST] Base64编码测试: Hello → " .. 测试结果)
        添加日志("[TEST] 预期结果: SGVsbG8=")
        添加日志("[TEST] 测试结果: " .. (测试结果 == "SGVsbG8=" and "✅ 通过" or "❌ 失败"))
        
        if 测试结果 ~= "SGVsbG8=" then
          添加日志("[WARN] Base64编码可能有问题，但继续执行")
        end
        
        local base64内容 = 正确Base64编码(新代码清理)
        添加日志("Base64编码长度: " .. #base64内容)
        
        -- 获取文件当前SHA
        添加日志("[5] 获取文件当前SHA")
        local api地址 = 构建API地址("获取内容")
        local 请求头 = 构建API头()
        
        Http.get(api地址, nil, "UTF-8", 请求头, function(getCode, getResp)
          添加日志("[6] SHA响应: " .. getCode)
          
          if getCode == 200 then
            local json = require("cjson")
            local ok, fileInfo = pcall(json.decode, getResp)
            
            if ok and fileInfo and fileInfo.sha then
              local sha = fileInfo.sha
              添加日志("文件SHA: " .. sha:sub(1, 10) .. "...")
              
              -- 构建更新数据（符合官方API规范）
              local 更新数据 = {
                message = "云函数更新 - " .. os.date("%Y-%m-%d %H:%M:%S"),
                content = base64内容,
                sha = sha,
                -- 以下为可选参数，按照官方文档规范
                committer = {
                  name = "云函数编辑器",
                  email = "editor@cloudfunction.com"
                },
                author = {
                  name = "云函数编辑器",
                  email = "editor@cloudfunction.com"
                }
              }
              
              local json数据 = json.encode(更新数据)
              添加日志("[7] 准备上传更新")
              添加日志("JSON数据长度: " .. #json数据)
              
              -- 发送更新请求
              Http.put(api地址, json数据, 请求头, function(putCode, putResp)
                添加日志("[8] 上传结果: " .. putCode)
                
                local 对话框 = AlertDialog.Builder(activity)
                
                if putCode == 200 or putCode == 201 then
                  添加日志("[SUCCESS] ✅ 文件更新成功！")
                  对话框.setTitle("✅ 上传成功")
                  .setMessage("文件已成功更新到GitHub仓库")
                  
                  if putCode == 201 then
                    添加日志("新文件已创建")
                  elseif putCode == 200 then
                    添加日志("现有文件已更新")
                  end
                  
                else
                  添加日志("[ERROR] ❌ 上传失败")
                  local errMsg = "状态码: " .. putCode
                  
                  if putResp then
                    local ok2, resp = pcall(json.decode, putResp)
                    if ok2 and resp then
                      if resp.message then
                        errMsg = errMsg .. "\n错误: " .. resp.message
                        添加日志("GitHub错误: " .. resp.message)
                      end
                      
                      if resp.documentation_url then
                        添加日志("文档链接: " .. resp.documentation_url)
                      end
                      
                      if putCode == 409 then
                        errMsg = errMsg .. "\n冲突: 文件已被修改，请刷新后重试"
                      elseif putCode == 422 then
                        errMsg = errMsg .. "\n验证失败: 请检查参数格式"
                      end
                    else
                      errMsg = errMsg .. "\n响应: " .. putResp:sub(1, 200)
                    end
                  end
                  
                  对话框.setTitle("❌ 保存失败")
                  .setMessage(errMsg)
                end
                
                对话框.setPositiveButton("复制日志", function()
                  复制到剪贴板(日志内容)
                  Toast.makeText(activity, "日志已复制到剪贴板", 1000).show()
                end)
                .setNeutralButton("查看详情", function()
                  local 详情 = string.format(
                    "仓库: %s/%s\n文件: %s\nAPI版本: %s\n代码长度: %d\nBase64长度: %d\nSHA: %s",
                    github配置.owner, github配置.repo, github配置.path,
                    github配置.api版本, #新代码, #base64内容,
                    sha and sha:sub(1, 10) .. "..." or "无"
                  )
                  
                  AlertDialog.Builder(activity)
                  .setTitle("API调用详情")
                  .setMessage(详情)
                  .setPositiveButton("确定", nil)
                  .show()
                end)
                .setNegativeButton("关闭", nil)
                .show()
              end)
              
            else
              添加日志("[ERROR] 无法解析SHA响应")
              Toast.makeText(activity, "获取文件信息失败", 1000).show()
            end
          else
            添加日志("[ERROR] 获取SHA失败: " .. getCode)
            Toast.makeText(activity, "无法获取文件信息: " .. getCode, 1000).show()
          end
        end)
      end)
      .setNegativeButton("取消", function()
        添加日志("[CANCELLED] 用户取消操作")
        AlertDialog.Builder(activity)
        .setTitle("已取消")
        .setMessage("操作已取消")
        .setPositiveButton("复制日志", function()
          复制到剪贴板(日志内容)
          Toast.makeText(activity, "日志已复制", 800).show()
        end)
        .setNegativeButton("关闭", nil)
        .show()
      end)
      .show()
      
    else
      添加日志("[ERROR] 无法获取云函数内容: " .. code)
      AlertDialog.Builder(activity)
      .setTitle("读取失败")
      .setMessage("HTTP状态码: " .. code)
      .setPositiveButton("复制日志", function()
        复制到剪贴板(日志内容)
        Toast.makeText(activity, "日志已复制", 800).show()
      end)
      .setNegativeButton("确定", nil)
      .show()
    end
  end)
end

都给我低调点好吧白壳科技牛逼