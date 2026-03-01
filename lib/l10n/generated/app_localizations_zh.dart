// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '密码本';

  @override
  String get unlock => '解锁';

  @override
  String get enterMasterPassword => '输入主密码';

  @override
  String get incorrectPassword => '主密码不正确';

  @override
  String get myVault => '我的密码本';

  @override
  String get addPassword => '添加密码';

  @override
  String get newEntry => '新增条目';

  @override
  String get title => '标题';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get url => '网址';

  @override
  String get notes => '备注';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get add => '添加';

  @override
  String get delete => '删除';

  @override
  String get editEntry => '编辑条目';

  @override
  String get deleteEntry => '删除条目？';

  @override
  String get deleteWarning => '此操作无法撤销。';

  @override
  String get search => '搜索...';

  @override
  String get noPasswords => '暂无密码。点击 + 开始添加。';

  @override
  String copied(String label) {
    return '已复制';
  }

  @override
  String get useBiometrics => '使用生物识别';

  @override
  String get welcome => '欢迎使用';

  @override
  String get createVault => '创建密码库';

  @override
  String get onboardingSub => '创建一个强主密码来加密您的个人密码库。';

  @override
  String get storageLocation => '存储位置';

  @override
  String get defaultLocal => '默认 (仅限本地)';

  @override
  String get syncTip => '提示：选择 iCloud Drive 或 厂商云同步文件夹可实现跨设备同步。';

  @override
  String get recoveryWarning => '重要：如果您忘记此密码，数据将无法找回。我们不在服务器存储您的密码。';

  @override
  String get attachments => '附件';

  @override
  String get addFile => '添加证书/文件';

  @override
  String get settings => '设置';

  @override
  String get appearance => '外观';

  @override
  String get themeMode => '主题模式';

  @override
  String get language => '语言';

  @override
  String get security => '安全';

  @override
  String get vaultPath => '路径';

  @override
  String get system => '跟随系统';

  @override
  String get dark => '深色';

  @override
  String get light => '浅色';

  @override
  String get passwordsDoNotMatch => '两次密码输入不一致';

  @override
  String get passwordTooShort => '密码长度至少为 8 位';

  @override
  String get import => '导入';

  @override
  String get export => '导出';

  @override
  String get confirmDelete => '确认删除？';

  @override
  String get cancelCaps => '取消';

  @override
  String get deleteCaps => '删除';

  @override
  String get saveCaps => '保存';

  @override
  String get systemDefault => '系统默认';

  @override
  String get autoLockTimeout => '自动锁屏延迟';

  @override
  String seconds(int count) {
    return '$count秒';
  }

  @override
  String get importPrompt => '是否现在导入您已有的密码？';

  @override
  String get importNow => '立即导入';

  @override
  String get skip => '跳过';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get resetWithBiometrics => '使用生物识别解锁';

  @override
  String get unlockWithFaceID => '使用面容 ID 解锁';

  @override
  String get unlockWithTouchID => '使用触控 ID 解锁';

  @override
  String get createNewVault => '重置密码本';

  @override
  String get resetWarning => '重要提示：此操作无法撤销！\n您的所有数据将被永久删除。\n确认要重置吗？';

  @override
  String get confirmReset => '确认重置';

  @override
  String get biometricResetReason => '验证身份以解锁';

  @override
  String get vaultResetSuccess => '密码库已重置，请创建新的主密码。';

  @override
  String get noBiometricsAvailable => '无可用生物识别，只能创建新密码库。';

  @override
  String get oldVaultBackup => '旧密码库已备份为 vault_backup.db';

  @override
  String get credentials => '认证信息';

  @override
  String get notSet => '未设置';

  @override
  String get copyAll => '复制全部';

  @override
  String get allDetailsCopied => '已复制全部信息到剪贴板';

  @override
  String get show => '显示';

  @override
  String get hide => '隐藏';

  @override
  String get enlarge => '放大';

  @override
  String get copy => '复制';

  @override
  String get couldNotOpenFile => '无法打开文件';

  @override
  String get aboutDescription => '极简安全的跨平台密码管理器';

  @override
  String get resetPassword => '重置密码';

  @override
  String get enterCurrentPassword => '请输入当前密码';

  @override
  String get enterNewPassword => '请输入新密码';

  @override
  String get confirmNewPassword => '请再次输入新密码';

  @override
  String get passwordResetSuccess => '密码重置成功';

  @override
  String get passwordResetFailed => '密码重置失败';

  @override
  String get incorrectCurrentPassword => '当前密码错误';

  @override
  String get importDescription => '从 CSV 导入密码';

  @override
  String get data => '数据';

  @override
  String get importHint => 'CSV 格式：标题/账号/密码/备注';

  @override
  String get basicInfo => '基本信息';

  @override
  String get titleHint => '例如：Gmail、Netflix';

  @override
  String get usernameHint => '用户名或邮箱';

  @override
  String get passwordHint => '密码';

  @override
  String get notesHint => '备注信息...';

  @override
  String get noAttachments => '暂无附件';

  @override
  String get vertical => '纵向';

  @override
  String get horizontal => '横向';

  @override
  String get copyPassword => '复制密码';

  @override
  String importSuccess(int count) {
    return '成功导入 $count 条记录';
  }

  @override
  String importFailed(int count) {
    return '导入失败 $count 条记录';
  }

  @override
  String get importFormatHint =>
      '支持带表头的 CSV 格式。推荐使用 Chrome、1Password、Bitwarden 导出的带列标题的 CSV 文件。';

  @override
  String get importNoHeaderHint => '无表头 CSV 格式顺序：标题、网址、账号、密码、备注';

  @override
  String get confirm => '确认';

  @override
  String get deleteSelected => '删除选中';

  @override
  String deleteSelectedConfirm(int count) {
    return '确定删除 $count 条记录？';
  }

  @override
  String get selectItems => '选择要删除的项目';

  @override
  String selected(int count) {
    return '已选择 $count 项';
  }

  @override
  String get resetVaultTitle => '重置密码本？';

  @override
  String get resetVaultWarning => '这将永久删除您设备上的所有密码和数据。此操作无法撤销。\n\n您确定要继续吗？';

  @override
  String get importSmart => '智能导入';

  @override
  String get importChrome => 'Google Chrome';

  @override
  String get import1Password => '1Password';

  @override
  String get recommended => '推荐';

  @override
  String get securityWarning => '安全警告：导入完成后，请立即删除您的 CSV 文件！它包含未加密的明文密码。';

  @override
  String get importResult => '导入结果';

  @override
  String get trayPanelTitle => '快捷访问';

  @override
  String get openMainWindow => '打开主窗口';

  @override
  String get exitApp => '退出应用';

  @override
  String get recentPasswords => '最近使用';

  @override
  String get noRecentPasswords => '暂无最近使用的密码';

  @override
  String get quickSearch => '快速搜索...';

  @override
  String get viewAll => '查看全部';

  @override
  String get trayPanelLocked => '密码本已锁定';

  @override
  String get unlockVault => '解锁密码本';

  @override
  String get useBiometricUnlock => '使用生物识别';

  @override
  String get quickAccess => '快捷访问';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get lockNow => '立即锁定';

  @override
  String get quickSettings => '快速设置';

  @override
  String get passwordCopied => '密码已复制';
}
