import Foundation

enum AliasLexicon {
    static func extraAliases(for names: [String]) -> [String] {
        var values = Set<String>()
        for name in names {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            values.insert(FuzzyMatcher.normalize(trimmed))
            if let mapped = table[trimmed] {
                mapped.forEach { values.insert(FuzzyMatcher.normalize($0)) }
            }
            for (key, aliases) in table where trimmed.contains(key) {
                aliases.forEach { values.insert(FuzzyMatcher.normalize($0)) }
            }
        }
        return Array(values)
    }

    private static let table: [String: [String]] = [
        "谷歌": ["guge", "google"],
        "学术": ["xueshu", "scholar"],
        "小红书": ["xiaohongshu", "xhs", "red"],
        "红书": ["hongshu", "xhs"],
        "锁屏": ["suoping", "lock"],
        "查找": ["chazhao", "find"],
        "文件": ["wenjian", "file"],
        "微信": ["weixin", "wechat", "wx"],
        "企业微信": ["qiyeweixin", "wecom", "wxwork"],
        "钉钉": ["dingding", "dingtalk", "ding"],
        "支付宝": ["zhifubao", "alipay"],
        "淘宝": ["taobao"],
        "腾讯会议": ["tengxunhuiyi", "wemeet", "tencentmeeting"],
        "网易云音乐": ["wangyiyun", "neteasemusic"],
        "哔哩哔哩": ["bilibili", "bili"],
        "百度": ["baidu"],
        "备忘录": ["beiwanglu", "notes"],
        "日历": ["rili", "calendar"],
        "设置": ["shezhi", "settings"],
        "系统设置": ["xitongshezhi", "settings"],
        "终端": ["zhongduan", "terminal"],
        "访达": ["fangda", "finder"],
        "邮件": ["youjian", "mail"],
        "信息": ["xinxi", "messages"],
        "地图": ["ditu", "maps"],
        "音乐": ["yinyue", "music"],
        "照片": ["zhaopian", "photos"],
        "预览": ["yulan", "preview"],
        "计算器": ["jisuanqi", "calculator"],
        "提醒事项": ["tixing", "reminders"],
    ]
}
