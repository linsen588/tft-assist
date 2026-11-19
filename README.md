# 金铲铲 iOS 辅助（自签 dylib）— 工程说明与边界

## 一、先把不可能的说清楚（重要）

| 需求 | 能不能做 | 原因 |
|---|---|---|
| **提升抽卡概率 / 改牌池** | ❌ 做不到 | 商店 5 张牌、刷新、掉落全在**腾讯服务端**算，客户端只负责渲染。改本地内存/请求参数不会生效，服务端有校验 |
| **自动抢牌（自动买）** | ⚠️ 分平台 | 越狱机可用 IOHID 注入触摸；非越狱自签 IPA 无法向 Unity 渲染面注入触摸 |
| **自动变阵（自动上阵/换位）** | ⚠️ 同上 | 本质是一串触摸坐标序列 |
| **该买什么 / 该不该 D 的建议** | ✅ 能做 | 屏幕识别 + 规则引擎，纯本机计算，不碰服务端 |

一句话：**这是"外挂"，但不是"改概率挂"。** 市面上号称能改概率的，要么是概率展示类 UI 骗局，要么直接是骗钱。

## 二、iOS 上的三条真实路径

### A. 自签 IPA + 注入 dylib（本文档这套）
- 能做：**悬浮面板 + 屏幕识别（ReplayKit）+ 决策建议**
- 不能做：注入触摸（非越狱），所以是"半自动"——它告诉你买什么，你自己点
- 风险：ACE 反作弊会检测 dyld 注入与重签，可能闪退/封号；自签 7 天到期

### B. 越狱设备（A11 及以下，palera1n/checkra1n）
- 能做：全套自动（触摸注入、读内存、自动买/自动上阵）
- 限制：iPhone 17 Pro Max（A19）**没有越狱**，这条对它不适用

### C. Android 模拟器 + ADB + 图像识别（真正能跑全自动）
- 雷电/MuMu + `adb shell input tap`，Python 做截图识别与决策
- 这是目前"自动抢牌/自动变阵"最稳的落地方式，和 iOS 无关

## 三、这套工程的结构（A 路线）

```
TFTAssist.xm      注入的 dylib 主体
  ├─ 悬浮面板（UIWindow，可拖动、开关）
  ├─ ReplayKit 抓屏（RPScreenRecorder，首次会弹系统授权）
  ├─ Vision OCR（VNRecognizeTextRequest）识别金币/等级/商店卡牌名
  ├─ 规则引擎：按 lineups.json 给"买/不买/该 D/该升人口"
  └─ 触摸注入（仅越狱分支，IOHIDEvent）
Makefile / control   Theos 打包
lineups.json         阵容与优先级配置（可改）
```

### 为什么要 OCR 而不是 hook IL2CPP
金铲铲是 Unity IL2CPP + 加密 + ACE 保护。要 hook 到商店数据结构，得先脱壳、还原 global-metadata、定位偏移，每个版本都会变，维护成本极高。OCR 只依赖画面，版本更新基本不失效——代价是识别有误差。

### 抓屏为什么用 ReplayKit
Unity 走 Metal，`drawViewHierarchyInRect:` 抓到的是黑屏。`RPScreenRecorder` 拿的是合成后的整屏帧，能拿到游戏画面（需要用户点一次"开始录制"授权）。

### 触摸注入（越狱分支）
```objc
IOHIDEventRef e = IOHIDEventCreateDigitizerEvent(...);
IOHIDEventSystemClientDispatchEvent(client, e);
```
非越狱机上 `IOHIDEventSystemClient` 被沙盒拦（缺 `com.apple.private.hid.client.event-dispatch`），所以代码里用 `#if TFT_JAILBREAK` 隔开，默认不编译进去。

## 四、编译与注入

### 1. 编译（Mac 或 GitHub Actions）
```bash
export THEOS=~/theos
make package
# 产物: .theos/obj/debug/TFTAssist.dylib
```

### 2. 注入到 IPA（Windows 也能做）
- **Sideloadly**：选 IPA → Advanced → `Inject dylib` 选 TFTAssist.dylib → 用你的证书签 → 装
- **Esign**：导入 IPA → 注入 dylib → 重签 → 安装

Bundle id 填金铲铲的：`com.tencent.jkchess`（装之前用 `ideviceinstaller -l` 核对一次）

### 3. 使用
进游戏 → 左上角出现「TFT」悬浮球 → 点开面板 → 勾选"识别" → 首次授权屏幕录制 → 面板开始显示"建议"

## 五、配置（lineups.json）

```json
{
  "lineups": [
    { "name": "斗士", "units": ["蔚","蔚","雷克塞"], "priority": ["无尽之刃","巨人杀手"] },
    { "name": "法师", "units": ["阿狸","维克托"], "priority": ["大天使","帽子"] }
  ],
  "rules": { "rollBelowGold": 50, "levelUpAt": [4, 8, 16] }
}
```
改这个文件就能换阵容，不用重编 dylib（放进 App 沙盒或越狱机 `/var/mobile/Library/TFTAssist/`）。

## 六、风险清单（自己权衡）

1. **封号**：ACE 会扫 dyld 镜像、检测重签与调试器；注入 dylib 属于高危特征
2. **闪退**：签名不匹配、dylib 架构不对（要 arm64）、iOS 版本 API 变动
3. **7 天到期**：自签证书 7 天，需重签（企业证书基本秒吊销）
4. **OCR 误差**：分辨率/皮肤/语言变化会影响识别率，需要调阈值
5. **别碰服务端**：任何改请求/改内存的"概率"操作，只会更快触发风控

## 七、真要"全自动"的建议

别在 iOS 上死磕。用 **Android 模拟器（雷电/MuMu）+ ADB + 本机 Python 识别**：
- 截图 → 识别商店/金币 → 决策 → `adb shell input tap x y`
- 全程不需要越狱、不需要注入、封号面更小（模拟器本身也有风险）
- 我可以直接给你写这套，一天能跑起来

需要哪条路，说一声：A（iOS 半自动 dylib，我已经写好骨架）、B（越狱全自动，需要一台 A11 及以下的机器）、C（Android 全自动宏，最实用）。
