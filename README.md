# WatchCat-OTA

[WatchCat（喵哨）服务器监控 App](https://github.com/hemo528/WatchCat-Server-Monitor) 的 OTA 更新仓库。

App 每次冷启动会在后台读取本仓库的 `version.json`；发现 `versionCode` 比已安装版本大时弹窗提示更新（每天最多提醒一次），也可以在 App 的「设置 → 应用更新」里手动检查。更新包通过 HTTPS 下载，并用 `version.json` 里的 SHA-256 校验后再交给系统安装器。

## 目录结构

```
version.json              # 更新清单（App 读取的唯一入口）
apk/watchcat-<版本>.apk   # 各版本安装包
scripts/publish-ota.ps1   # 发布新版本的脚本
```

## version.json 格式

```json
{
  "versionCode": 7,
  "versionName": "1.2.2",
  "apkUrl": "https://raw.githubusercontent.com/hemo528/WatchCat-OTA/main/apk/watchcat-1.2.2.apk",
  "changelog": "更新说明（可换行）",
  "sizeBytes": 23753786,
  "sha256": "270269141c752221cb6213f55dded8cff95d1804b6a5e03792a1058beb2c5cf2",
  "publishedAt": "2026-11-10"
}
```

- `apkUrl` 必须是 HTTPS 且以 `.apk` 结尾
- `sizeBytes` 与 `sha256` 用于下载完整性校验（sha256 为 64 位十六进制）
- `versionCode` 必须大于 App 当前的 `BuildConfig.VERSION_CODE` 才会提示更新

清单地址：<https://raw.githubusercontent.com/hemo528/WatchCat-OTA/main/version.json>

## 发布新版本

1. 修改 `app/build.gradle.kts` 里的 `versionCode` / `versionName`，构建 debug APK：

   ```powershell
   .\gradlew.bat assembleDebug
   ```

2. 在本仓库根目录执行发布脚本：

   ```powershell
   .\scripts\publish-ota.ps1 `
       -ApkPath 'C:\path\to\app-debug.apk' `
       -VersionCode 8 `
       -VersionName '1.2.3' `
       -Changelog "1.2.3 更新：修复若干问题"
   ```

   脚本会把 APK 复制到 `apk/`、计算大小与 SHA-256、重写 `version.json`，然后 `git commit` + `git push`。

3. 推送后 `raw.githubusercontent.com` 有几分钟 CDN 缓存，稍等再在 App 里检查更新即可。

## 签名说明（重要）

App 目前以 **debug 签名**侧载分发，OTA 包必须使用**同一张调试证书**签名（默认构建即可），否则系统会拒绝覆盖安装。

如果将来切换到 release 签名，已安装用户需要先卸载旧版再安装一次，之后的 OTA 才能继续沿用新证书。
