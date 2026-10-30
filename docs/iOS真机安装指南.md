# 把「清账」装进 iPhone

工程位置：`C:\软件开发\记账软件`
当前状态：iPhone 已经被 Windows 正确识别（`Apple iPhone` + `Apple Mobile Device USB Composite Device`），
但 **Windows 无法给 iOS 设备编译/签名安装 App**，这一步必须在 macOS 上完成。

| 路线 | 需要什么 | 耗时 | 装好后有效期 |
| --- | --- | --- | --- |
| A. 直接在 Mac 上跑 | 一台 Mac + Xcode | 20 分钟 | 免费 Apple ID 7 天；付费账号 1 年 |
| B. 云端打包 IPA + Windows 侧载 | GitHub 账号 + Git + Sideloadly | 30–40 分钟 | 7 天，到期重签一次（不用重新打包） |
| C. 付费开发者账号 + TestFlight | $99/年 | 半天 | 每个构建 90 天 |

---

## 路线 A：借一台 Mac（最省事，推荐）

```bash
# 1. 把整个「记账软件」文件夹拷到 Mac
cd 记账软件

# 2. 装依赖（第一次会自动生成 Podfile 并 pod install，不用手动执行）
flutter pub get

# 3a. 只看效果：模拟器
open -a Simulator
flutter run -d "iPhone 16"

# 3b. 装到真机：iPhone 用数据线连 Mac
flutter devices          # 记下设备名
flutter run -d "iPhone"
```

真机第一次运行会卡在签名，按提示处理：

1. Xcode → Settings → Accounts → 加自己的 Apple ID
2. 打开 `ios/Runner.xcworkspace` → 选中 `Runner` target → Signing & Capabilities
3. Team 选刚加的 Apple ID；Bundle Identifier 改成唯一值，例如 `com.你的名字.qingzhang`
4. 回到终端重新 `flutter run -d "iPhone"`
5. iPhone 上：设置 → 通用 → VPN 与设备管理 → 信任你的开发者证书

## 路线 B：没有 Mac，用 GitHub Actions 打包 + Sideloadly 侧载

仓库里已经放好了流水线：[`.github/workflows/ios-ipa.yml`](../.github/workflows/ios-ipa.yml)
（在 macOS runner 上 `flutter build ios --release --no-codesign`，产出未签名 IPA）。

1. 装 Git for Windows（本机还没有）：`winget install Git.Git`
2. 在 GitHub 建一个仓库（私有即可），把项目推上去
3. 仓库 → Actions → `build-ios-ipa` → Run workflow
4. 跑完在 Artifacts 里下载 `qingzhang-unsigned-ipa`
5. Windows 上装 [Sideloadly](https://sideloadly.io)：连 iPhone → 选 IPA → 填 Apple ID（会走双重认证）→ Start
6. iPhone：设置 → 通用 → VPN 与设备管理 → 信任你的 Apple ID
7. 到期（7 天）后重跑一次 Sideloadly 即可，**不需要重新打包**

注意事项：

- 免费 Apple ID 最多同时签 3 个自签 App；装了第 4 个会顶掉前一个
- Bundle ID 冲突时，在 Sideloadly 里勾选修改 Bundle ID
- 本机已有 Apple 驱动（系统能识别设备），若 Sideloadly 报找不到设备，再装一次 iTunes 或 Microsoft Store 的「Apple Devices」

## 路线 C：付费开发者账号

有 $99/年的 Apple Developer Program 时，可以走 TestFlight：App Store Connect 建 App → 用 Transporter 上传 IPA →
内部测试（90 天有效，可长期续），也可以直接提审上架。

---

## 装好后怎么验证「付款/收款自动记账」

1. 打开「清账」，首页应该已经有三个月示例数据
2. 打开「快捷指令」App → 新建 → 添加操作「打开 URL」→ 填：
   `qingzhang://add?amount=12&category=餐饮&note=午餐`
3. 运行这个快捷指令，App 应该弹「已自动记账 · 餐饮 12.00 元」，并且不用点任何按钮
4. 想更懒：设置 → 辅助功能 → 触控 → 轻点背面 → 轻点两下 → 绑定这个快捷指令

## 常见问题

| 现象 | 原因 / 处理 |
| --- | --- |
| Sideloadly 提示找不到设备 | 装 iTunes 或「Apple Devices」补全驱动；换原装数据线 |
| 安装到一半失败 | 免费账号证书数量到上限；先删掉一个旧的自签 App |
| App 闪退 | 确认 iPhone 系统 ≥ iOS 15（工程 deployment target 是 15.0） |
| 链接打不开 | 只有重装后 URL Scheme 才注册；确认用「快捷指令 → 打开 URL」，Safari 地址栏不一定放行自定义 scheme |
| 7 天后图标变灰 | 正常，免费签名过期，重跑 Sideloadly |
