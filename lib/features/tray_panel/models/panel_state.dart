/// Panel 窗口状态模型
class PanelState {
  /// Panel 是否可见
  final bool isVisible;

  /// Panel 是否处于激活状态
  final bool isActive;

  /// 当前是否为 Panel 模式（而非主窗口模式）
  final bool isPanelMode;

  const PanelState({
    this.isVisible = false,
    this.isActive = false,
    this.isPanelMode = false,
  });

  PanelState copyWith({
    bool? isVisible,
    bool? isActive,
    bool? isPanelMode,
  }) {
    return PanelState(
      isVisible: isVisible ?? this.isVisible,
      isActive: isActive ?? this.isActive,
      isPanelMode: isPanelMode ?? this.isPanelMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelState &&
          runtimeType == other.runtimeType &&
          isVisible == other.isVisible &&
          isActive == other.isActive &&
          isPanelMode == other.isPanelMode;

  @override
  int get hashCode =>
      isVisible.hashCode ^ isActive.hashCode ^ isPanelMode.hashCode;

  @override
  String toString() {
    return 'PanelState(isVisible: $isVisible, isActive: $isActive, isPanelMode: $isPanelMode)';
  }
}
