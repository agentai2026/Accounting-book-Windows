/// 毛玻璃视觉参数（亮/暗模式）

class GlassConstants {

  GlassConstants._();



  /// 背景模糊强度

  static const double blurSigma = 44;



  /// 弹窗额外加强模糊

  static const double dialogBlurSigma = 52;



  /// 面板叠色透明度（越高磨砂感越强、越不透明）

  static const double lightTintOpacity = 0.66;

  static const double darkTintOpacity = 0.54;



  /// 高光边 / 描边

  static const double lightBorderOpacity = 0.96;

  static const double darkBorderOpacity = 0.34;



  /// 内发光（左上高光）

  static const double lightSheenOpacity = 0.72;

  static const double darkSheenOpacity = 0.16;



  /// 弹窗遮罩

  static const double barrierOpacity = 0.62;

}

