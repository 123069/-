# 在 Mac 上把「清账」装进 iPhone（照着做，约 20 分钟）

> 项目压缩包：`C:\软件开发\记账软件\dist\qingzhang-mac.zip`
> 传到 Mac 后**解压并重命名成 `qingzhang`**，放在 `~/dev/qingzhang` 这类纯英文路径下（避免中文路径带来的构建问题）。

## 0. 检查清单

- [ ] Mac（macOS 13 或更新）
- [ ] Xcode（App Store 装最新版，第一次打开要等它装组件）
- [ ] Flutter SDK（macOS 版）
- [ ] CocoaPods
- [ ] iPhone 数据线（原装或能传数据的线）
- [ ] iPhone 系统 ≥ iOS 15

```bash
# Flutter：有 Homebrew 的话最省事
brew install --cask flutter
flutter --version

# CocoaPods
brew install cocoapods   # 或 sudo gem install cocoapods
```

如果没装 Homebrew，也可以去 flutter.dev 下载 mac 版 zip，解压后把 `flutter/bin` 加进 PATH。

## 1. 先在模拟器里跑通（5 分钟，用来排除代码问题）

```bash
cd ~/dev/qingzhang
flutter pub get
open -a Simulator          # 等模拟器启动
flutter run -d "iPhone 16" # 设备名以 flutter devices 的输出为准
```

> 第一次跑会自动生成 `ios/Podfile` 并执行 `pod install`，**不要手动先跑 `pod install`**（那时 Podfile 还不存在，会报找不到 Podfile）。

看到首页有账目、底部四个标签能切换，说明代码没问题。
接下来真机失败就只可能是签名问题，能省很多时间。

> 模拟器效果和手机一致；**只有模拟器**里可以用
> `xcrun simctl openurl booted "qingzhang://add?amount=12&category=餐饮"` 验证自动入账。

## 2. 装到真机

### 2.1 手机这边

1. 用数据线把 iPhone 连 Mac，手机上点 **「信任」**
2. iOS 16 及以上必须开开发者模式：
   **设置 → 隐私与安全性 → 开发者模式 → 打开 → 重启手机 → 开机后再确认一次**

### 2.2 Xcode 这边

1. Xcode → 菜单 **Settings → Accounts → +** → 登录自己的 Apple ID（免费账号即可）
2. 终端里执行：
   ```bash
   open ios/Runner.xcworkspace     # 注意是 xcworkspace，不是 xcodeproj
   ```
3. 左侧选中 **Runner** → 右侧 **Signing & Capabilities**：
   - **Team** 选刚加的 Apple ID（会显示成 `你的名字 (Personal Team)`）
   - **Bundle Identifier** 改成唯一的，例如 `com.你的拼音.qingzhang`
     （默认 `com.qingzhang.qingzhang` 可能被别人占用，冲突就装不上）
4. 顶部设备列表选中你的 iPhone → 点 ▶️

### 2.3 手机上收尾

1. 首次运行会提示「不受信任的开发者」：
   **设置 → 通用 → VPN 与设备管理 → 你的 Apple ID → 信任**
2. 回桌面，图标「清账」就在那儿了，点开即用

## 3. 如果编译报错

**只在 `AppDelegate.swift` / `SceneDelegate.swift` 报错**（这两处是我加的深链入口，没在 Mac 上编译过）：

```bash
cp docs/fallback/AppDelegate.swift  ios/Runner/AppDelegate.swift
cp docs/fallback/SceneDelegate.swift ios/Runner/SceneDelegate.swift
```

然后重新 ▶️。App 全部功能都正常，只有 `qingzhang://` 自动入账暂时不可用；
把报错信息发我，我改好再给你。

**报错在别处**：把 Xcode 里红色的那几行发我即可。

## 4. 装好之后验证「付款即可记账」

1. 打开「快捷指令」→ 新建 → 添加操作「打开 URL」→ 填入
   `qingzhang://add?amount=12&category=餐饮&note=午餐`
2. 运行 → 清账应弹出「已自动记账 · 餐饮 12.00 元」，全程不用点按钮
3. 想更省事：**设置 → 辅助功能 → 触控 → 轻点背面 → 轻点两下** → 选这个快捷指令

## 5. 免费账号的两个限制

- **7 天有效期**：到期图标点不开，重新在 Xcode 里 Run 一次即可（数据不会丢）
- **最多 3 个自签 App**：装第 4 个会顶掉最早的一个

## 6. 常见问题

| 现象 | 处理 |
| --- | --- |
| `pod install` 报错 | 先 `pod repo update`，仍失败就删掉 `ios/Pods` 和 `ios/Podfile.lock` 重来 |
| 设备列表里没有 iPhone | 换线；手机上重新点「信任」；Xcode → Window → Devices and Simulators 看有没有识别 |
| 安装时报 Bundle ID 冲突 | 改成一个更独特的，例如 `com.你的名字.qingzhang` |
| 运行后白屏 | 先跑模拟器确认代码；白屏多半是签名或启动页问题，重装一次 |
| 深链没反应 | 用「快捷指令 → 打开 URL」，Safari 地址栏不一定放行自定义 scheme |
