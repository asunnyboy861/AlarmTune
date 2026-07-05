import SwiftUI

/// Dynamic Type 支持的字体修饰器（M9）
///
/// 关键技术点：`.font(.system(size:))` 不会随 Dynamic Type 缩放。
/// 使用 `@ScaledMetric` 属性包装器在 ViewModifier 内部缩放字号，
/// 这样既能用自定义基础字号，又能响应系统 Dynamic Type 设置。
///
/// 使用示例：
///   Text("Hello").dynamicFont(17, weight: .semibold)
///   Text("7:00 AM").fixedFont(48, weight: .bold)  // 闹钟时间不缩放
struct DynamicFontModifier: ViewModifier {
    @ScaledMetric private var scaledSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design) {
        self._scaledSize = ScaledMetric(wrappedValue: size)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize, weight: weight, design: design))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

extension View {
    /// 语义化字号（随 Dynamic Type 缩放）
    /// - Parameters:
    ///   - size: 基础字号（pt），作为 @ScaledMetric 的初始值
    ///   - weight: 字重
    ///   - design: 字体设计
    func dynamicFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(DynamicFontModifier(size: size, weight: weight, design: design))
    }

    /// 固定字号（不随 Dynamic Type 缩放）
    /// 用于闹钟时间等视觉主体场景，过大缩放会破坏布局
    func fixedFont(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        font(.system(size: size, weight: weight, design: design))
    }
}
